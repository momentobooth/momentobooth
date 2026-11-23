import 'dart:typed_data';

import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/print_renderer.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/stack_collector.dart';
import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

/// Sends a rendered sheet to the printer of [route]. Returns false when sending is skipped, e.g. in the debug settings;
/// throws when the printer fails.
typedef SendSheet = Future<bool> Function(String sheetName, PrintRoute route, Uint8List pdf);

/// Counts one copy at [size] in the statistics.
typedef CountPrint = void Function(PrintSize size);

typedef LogPrintError = void Function(String message, Object error, StackTrace stackTrace);

/// What happened while printing.
class PrintJobReport {

  /// Every distinct sheet that was rendered, or failed to render.
  final List<Future<Uint8List>> renderings;

  /// What was sent where, for the print job log.
  final List<Map<String, Object?>> sheets;

  /// The labels (or node IDs) of the printers that failed.
  final Set<String> failedPrinters;

  final int sentSheets;

  /// The copies of this print that wait on a stack in collect mode, to be printed with a later sheet. After printing
  /// collected sheets, every copy that still waits.
  final int waitingCopies;

  /// Why the print failed, or null when every copy was printed or is waiting.
  final PrintingException? failure;

  const PrintJobReport({
    required this.renderings,
    required this.sheets,
    required this.failedPrinters,
    required this.sentSheets,
    this.waitingCopies = 0,
    required this.failure,
  });

}

/// Prints the copies of a photo along the routes of a [PrintRouter]: renders their sheets, sends them and counts them.
///
/// Everything outside the routing (printers, statistics, logging, where waiting copies are kept) is passed in, so this
/// can run without the app.
class PrintJobRunner {

  final SendSheet sendSheet;
  final CountPrint countPrint;
  final LogPrintError logError;

  const PrintJobRunner({required this.sendSheet, required this.countPrint, required this.logError});

  /// Prints [copies] copies of [image] at [size]. Every copy follows its own route through [router].
  ///
  /// A printer that fails is skipped where the routing offers another one: a round-robin node tries its next output, a
  /// duplicate node still prints on its other outputs. Printing stops when no printer takes a copy.
  ///
  /// Copies that pass a stack node are put on the stack's sheets together, which are printed once all copies are
  /// routed, also when a later copy could not be printed. A printer that fails then cannot be replaced by another one.
  /// For a stack in collect mode, the copies are added to the [collector] instead, and the sheets that are full are
  /// printed. Copies on a sheet that fails keep waiting. Without a [collector], every stack prints directly.
  Future<PrintJobReport> run(
    PrintRouter router, {
    required String jobName,
    required Uint8List image,
    required PrintSize size,
    required int copies,
    StackCollector? collector,
  }) async {
    final bool split = size == PrintSize.split;
    final session = _PrintSession(this);
    // The route and the copies of each stack node the copies pass, in direct and in collect mode.
    final Map<String, (PrintRoute, List<int>)> stacks = {}, collecting = {};

    int? unprintedCopy;
    for (int copy = 1; copy <= copies; copy++) {
      final printed = await router.printCopy(size, (route) async {
        if (route.stackNodeId case final stackNodeId?) {
          final collects = collector != null && route.stack?.mode == StackMode.collect;
          ((collects ? collecting : stacks)[stackNodeId] ??= (route, [])).$2.add(copy);
          return true;
        }
        return session.printSheet(
          "$jobName | ${size.label} | copy $copy / $copies",
          route,
          log: {'copies': [copy]},
          counts: [size],
          renderKey: route.renderKey,
          render: () => renderPrintPdf(image, route, split: split),
        );
      });
      if (!printed) {
        unprintedCopy = copy;
        break;
      }
    }

    // The copies that are already stacked are printed in any case.
    bool stacksPrinted = true;
    for (final MapEntry(key: stackNodeId, value: (route, stackedCopies)) in stacks.entries) {
      final printed = await session.printSheet(
        "$jobName | ${size.label} | ${stackedCopies.length} of $copies copies stacked",
        route,
        log: {'copies': stackedCopies},
        counts: [for (final _ in stackedCopies) size],
        renderKey: (stack: stackNodeId),
        render: () => renderStackPdf([for (final _ in stackedCopies) StackedCopy(image, split: split)], route),
      );
      if (!printed) stacksPrinted = false;
    }

    int waitingCopies = 0;
    if (collecting.isNotEmpty) {
      final aspectRatio = photoAspectRatio(image);
      waitingCopies = await collector!.locked(() async {
        final printIds = <String>{};
        for (final MapEntry(key: stackNodeId, value: (route, collectedCopies)) in collecting.entries) {
          printIds.add(await collector.add(
            stackNodeId: stackNodeId,
            jobName: jobName,
            size: size,
            image: image,
            aspectRatio: aspectRatio,
            count: collectedCopies.length,
          ));
          await session.printCollected(collector, route, stackNodeId);
        }
        return collector.copies.where((copy) => printIds.contains(copy.printId)).length;
      });
    }

    return session.report(
      waitingCopies: waitingCopies,
      failure: switch ((unprintedCopy, stacksPrinted)) {
        (final copy?, _) => PrintingException('No printer took copy $copy / $copies at ${size.label}', sentSheets: session.sentSheets),
        (null, false) => PrintingException('Not all stacked copies at ${size.label} were printed', sentSheets: session.sentSheets),
        (null, true) => null,
      },
    );
  }

  /// Prints the sheets of the copies waiting on stacks, the last one of a stack included when it is not full: of the
  /// stacks [where] accepts, or of every stack. Copies on a stack that does not reach a printer keep waiting.
  ///
  /// The stacks are chosen once the actions before this one on the [collector] are done.
  Future<PrintJobReport> printCollected(
    PrintRouter router,
    StackCollector collector, {
    bool Function(String stackNodeId, StackNodeData stack)? where,
  }) => collector.locked(() async {
    final session = _PrintSession(this);
    for (final stackNodeId in {for (final copy in collector.copies) copy.stackNodeId}) {
      final route = router.stackRoute(stackNodeId);
      if (route == null || !(where?.call(stackNodeId, route.stack!) ?? true)) continue;
      await session.printCollected(collector, route, stackNodeId, includeUnfull: true);
    }
    return session.report(
      waitingCopies: collector.copies.length,
      failure: session.failedPrinters.isEmpty
          ? null
          : PrintingException('Not all collected sheets were printed', sentSheets: session.sentSheets),
    );
  });

  /// Prints the sheets of the stacks that waited long enough, see [printCollected]: a stack in collect mode once no
  /// copy was added for its [StackNodeData.printAfterIdleMinutes], and a stack that now prints right away.
  Future<PrintJobReport> printIdleStacks(PrintRouter router, StackCollector collector, {required DateTime now}) =>
      printCollected(router, collector, where: (stackNodeId, stack) => switch (stack.mode) {
        StackMode.direct => true,
        StackMode.collect => stack.printAfterIdleMinutes > 0 &&
            !now.isBefore(collector.lastAddedAt(stackNodeId)!.add(Duration(minutes: stack.printAfterIdleMinutes))),
      });

}

/// The sheets sent for one print, or for one round of printing collected sheets.
class _PrintSession {

  final PrintJobRunner runner;

  // Within a session, every distinct sheet is rendered once.
  final Map<Object, Future<Uint8List>> renderings = {};
  final List<Map<String, Object?>> sheets = [];
  final Set<String> failedPrinters = {};
  int sentSheets = 0;

  _PrintSession(this.runner);

  /// Renders a sheet once and sends it. Counts a copy for every size in [counts] once it is sent. Returns whether the
  /// printer took it.
  Future<bool> printSheet(
    String sheetName,
    PrintRoute route, {
    required Map<String, Object?> log,
    required List<PrintSize> counts,
    required Object renderKey,
    required Future<Uint8List> Function() render,
  }) async {
    final sheet = <String, Object?>{
      ...log,
      'printer': route.printer.label,
      'backend': route.printer.backend.name,
      'queue': route.printer.queueId,
      'media': route.printer.media.toJson(),
      'margins': route.margins.toJson(),
      'layout': route.layout?.toJson(),
      'stack': route.stack?.toJson(),
    };
    sheets.add(sheet);
    try {
      final pdf = await (renderings[renderKey] ??= render());
      if (await runner.sendSheet(sheetName, route, pdf)) {
        sentSheets++;
        counts.forEach(runner.countPrint);
      }
      return true;
    } catch (error, stackTrace) {
      runner.logError("Failed to print $sheetName with [${route.printer.label}]", error, stackTrace);
      sheet['error'] = '$error';
      failedPrinters.add(route.printer.label.isEmpty ? route.printerNodeId : route.printer.label);
      return false;
    }
  }

  /// Prints the sheets of the copies waiting on [stackNodeId]: the full ones, and with [includeUnfull] the last one as
  /// well. A sheet that is printed is removed from the [collector]; the copies of a sheet that fails keep waiting.
  /// Copies whose photo cannot be read any more are dropped, as they can never be printed.
  Future<void> printCollected(StackCollector collector, PrintRoute route, String stackNodeId, {bool includeUnfull = false}) async {
    for (final sheet in collector.sheets(stackNodeId, route, includeUnfull: includeUnfull)) {
      final Map<String, Uint8List> images = {};
      final List<CollectedCopy> unreadable = [];
      for (final copy in sheet) {
        try {
          images[copy.imageFile] ??= await collector.readImage(copy);
        } catch (error, stackTrace) {
          runner.logError("Could not read the photo of collected copy ${copy.id} (${copy.jobName}), dropping it", error, stackTrace);
          unreadable.add(copy);
        }
      }
      if (unreadable.isNotEmpty) await collector.remove(unreadable);
      final printable = sheet.where((copy) => images.containsKey(copy.imageFile)).toList();
      if (printable.isEmpty) continue;

      final printed = await printSheet(
        "Collected sheet | ${printable.length} copies of ${{for (final copy in printable) copy.jobName}.join(', ')}",
        route,
        log: {'collected': [for (final copy in printable) {'job': copy.jobName, 'size': copy.size.name}]},
        counts: [for (final copy in printable) copy.size],
        renderKey: (collected: printable.first.id),
        render: () => renderStackPdf([
          for (final copy in printable) StackedCopy(images[copy.imageFile]!, split: copy.size == PrintSize.split),
        ], route),
      );
      if (printed) await collector.remove(printable);
    }
  }

  PrintJobReport report({int waitingCopies = 0, PrintingException? failure}) => PrintJobReport(
    renderings: renderings.values.toList(),
    sheets: sheets,
    failedPrinters: failedPrinters,
    sentSheets: sentSheets,
    waitingCopies: waitingCopies,
    failure: failure,
  );

}
