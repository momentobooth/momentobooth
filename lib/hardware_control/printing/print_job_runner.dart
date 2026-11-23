import 'dart:typed_data';

import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/print_renderer.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/models/settings.dart';

/// Sends a rendered sheet to the printer of [route]. Returns false when sending is skipped, e.g. in the debug settings;
/// throws when the printer fails.
typedef SendSheet = Future<bool> Function(String sheetName, PrintRoute route, Uint8List pdf);

/// Counts one copy at [size] in the statistics.
typedef CountPrint = void Function(PrintSize size);

typedef LogPrintError = void Function(String message, Object error, StackTrace stackTrace);

/// What happened while printing a photo.
class PrintJobReport {

  /// Every distinct sheet that was rendered, or failed to render.
  final List<Future<Uint8List>> renderings;

  /// What was sent where, for the print job log.
  final List<Map<String, Object?>> sheets;

  /// The labels (or node IDs) of the printers that failed.
  final Set<String> failedPrinters;

  final int sentSheets;

  /// Why the print failed, or null when every copy was printed.
  final PrintingException? failure;

  const PrintJobReport({
    required this.renderings,
    required this.sheets,
    required this.failedPrinters,
    required this.sentSheets,
    required this.failure,
  });

}

/// Prints the copies of a photo along the routes of a [PrintRouter]: renders their sheets, sends them and counts them.
///
/// Everything outside the routing (printers, statistics, logging) is passed in, so this can run without the app.
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
  Future<PrintJobReport> run(PrintRouter router, {required String jobName, required Uint8List image, required PrintSize size, required int copies}) async {
    final bool split = size == PrintSize.split;
    // Within one print, every distinct sheet is rendered once.
    final Map<Object, Future<Uint8List>> renderings = {};
    final List<Map<String, Object?>> sheets = [];
    final Set<String> failedPrinters = {};
    // The route and the copies of each stack node the copies pass.
    final Map<String, (PrintRoute, List<int>)> stacks = {};
    int sentSheets = 0;

    // Renders a sheet once and sends it. Returns whether the printer took it.
    Future<bool> printSheet(String sheetName, PrintRoute route, List<int> sheetCopies, Object renderKey, Future<Uint8List> Function() render) async {
      final sheet = <String, Object?>{
        'copies': sheetCopies,
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
        if (await sendSheet(sheetName, route, pdf)) {
          sentSheets++;
          for (final _ in sheetCopies) {
            countPrint(size);
          }
        }
        return true;
      } catch (error, stackTrace) {
        logError("Failed to print $sheetName with [${route.printer.label}]", error, stackTrace);
        sheet['error'] = '$error';
        failedPrinters.add(route.printer.label.isEmpty ? route.printerNodeId : route.printer.label);
        return false;
      }
    }

    int? unprintedCopy;
    for (int copy = 1; copy <= copies; copy++) {
      final printed = await router.printCopy(size, (route) async {
        if (route.stackNodeId case final stackNodeId?) {
          (stacks[stackNodeId] ??= (route, [])).$2.add(copy);
          return true;
        }
        return printSheet(
          "$jobName | ${size.label} | copy $copy / $copies",
          route,
          [copy],
          route.renderKey,
          () => renderPrintPdf(image, route, split: split),
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
      final printed = await printSheet(
        "$jobName | ${size.label} | ${stackedCopies.length} of $copies copies stacked",
        route,
        stackedCopies,
        (stack: stackNodeId),
        () => renderStackPdf(image, route, copies: stackedCopies.length, split: split),
      );
      if (!printed) stacksPrinted = false;
    }

    final PrintingException? failure = switch ((unprintedCopy, stacksPrinted)) {
      (final copy?, _) => PrintingException('No printer took copy $copy / $copies at ${size.label}', sentSheets: sentSheets),
      (null, false) => PrintingException('Not all stacked copies at ${size.label} were printed', sentSheets: sentSheets),
      (null, true) => null,
    };
    return PrintJobReport(
      renderings: renderings.values.toList(),
      sheets: sheets,
      failedPrinters: failedPrinters,
      sentSheets: sentSheets,
      failure: failure,
    );
  }

}
