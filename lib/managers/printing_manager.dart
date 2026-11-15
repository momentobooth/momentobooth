import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/hardware_control/printing/print_renderer.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;

part 'printing_manager.g.dart';

class PrintingManager = PrintingManagerBase with _$PrintingManager;

abstract class PrintingManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Printing system";

  final Map<PrinterBackend, PrintingSystemClient> _clients = {
    PrinterBackend.native: FlutterPrintingClient(),
    PrinterBackend.cups: CupsClient(),
  };

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Null initialize() {
    reaction((_) => getIt<SettingsManager>().settings.hardware.printRoutingGraph, _updateRouter, fireImmediately: true);
  }

  // /////// //
  // Routing //
  // /////// //

  @readonly
  PrintRouter _router = PrintRouter(PrintRoutingGraph.withDefaults());

  @action
  void _updateRouter(PrintRoutingGraph graph) {
    // The round-robin nodes start over with a new graph, which is fine after editing it.
    _router = PrintRouter(graph);
    if (_router.printableSizes.isEmpty) {
      reportSubsystemDisabled();
    } else if (_router.analysis.hasErrors) {
      reportSubsystemWarning(message: "The print routing graph has problems, which are listed on the Print routing settings page. Connections with problems are ignored.");
    } else {
      reportSubsystemOk();
    }
  }

  /// The print sizes that are routed to a printer. Empty when printing is disabled for the project.
  @computed
  Set<PrintSize> get printableSizes => getIt<ProjectManager>().settings.enablePrinting ? _router.printableSizes : const {};

  /// The print sizes users can choose for a photo. Split prints are not a choice, they follow from choosing normal
  /// for a collage of three photos, see [printSizeFor].
  List<PrintSize> choosableSizes({required bool isThreePhotoCollage}) =>
      choosablePrintSizes(printableSizes, isThreePhotoCollage: isThreePhotoCollage);

  bool canPrint({required bool isThreePhotoCollage}) => choosableSizes(isThreePhotoCollage: isThreePhotoCollage).isNotEmpty;

  /// The print size a photo is printed at when users choose [chosen]: a collage of three photos chosen at normal size
  /// is printed in halves, if that print size is routed to a printer.
  PrintSize printSizeFor(PrintSize chosen, {required bool isThreePhotoCollage}) =>
      chosen == PrintSize.normal && isThreePhotoCollage && printableSizes.contains(PrintSize.split) ? PrintSize.split : chosen;

  /// How many physical copies guests get from one print when they choose [chosen], or null when that depends on the
  /// printer it ends up at.
  ///
  /// A collage of three photos holds the photos twice, side by side, which end up as two copies: printed apart as a
  /// split print, or cut apart otherwise.
  int? copiesPerPrint(PrintSize chosen, {required bool isThreePhotoCollage}) {
    final photos = _router.photosPerCopy(printSizeFor(chosen, isThreePhotoCollage: isThreePhotoCollage));
    if (photos == null) return null;
    return isThreePhotoCollage ? photos * 2 : photos;
  }

  /// The printers the routing can send jobs to, without duplicates.
  Set<String> usedQueueIds(PrinterBackend backend) => {
    for (final printer in _router.usedPrinters)
      if (printer.backend == backend) printer.queueId,
  };

  // //////// //
  // Printing //
  // //////// //

  /// Prints [copies] copies of [image] at [size]. Every copy follows its own route through the print routing graph.
  ///
  /// Stops at the first sheet that cannot be rendered or sent. The [PrintingException] then tells how many sheets were
  /// sent before. The rendered sheets are kept in any case.
  Future<void> printPhoto({required String jobName, required Uint8List image, required PrintSize size, int copies = 1}) async {
    // Within one print, every distinct sheet is rendered once.
    final Map<Object, Future<Uint8List>> renderings = {};
    final List<Map<String, Object?>> printedSheets = [];
    int sentSheets = 0;

    try {
      await _printCopies(jobName, image, size, copies, renderings, printedSheets, onSent: () => sentSheets++);
    } catch (error, stackTrace) {
      if (sentSheets == 0) rethrow;
      logError("Printing $jobName stopped after $sentSheets sheet(s) were sent", error, stackTrace);
      Error.throwWithStackTrace(PrintingException('$error', sentSheets: sentSheets), stackTrace);
    } finally {
      await _keepPrintedPdfs(jobName, size, renderings.values, printedSheets);
    }
  }

  Future<void> _printCopies(
    String jobName,
    Uint8List image,
    PrintSize size,
    int copies,
    Map<Object, Future<Uint8List>> renderings,
    List<Map<String, Object?>> printedSheets, {
    required void Function() onSent,
  }) async {
    for (int copy = 1; copy <= copies; copy++) {
      final routes = _router.nextCopy(size);
      if (routes.isEmpty) throw PrintingException('No printer is routed for ${size.label}');

      for (final route in routes) {
        final pdfData = await (renderings[route.renderKey] ??= renderPrintPdf(image, route, split: size == PrintSize.split));
        final printer = route.printer;
        final sheetName = "$jobName | ${size.label} | copy $copy / $copies";

        final target = "[${printer.label}] (${printer.backend.name} queue [${printer.queueId}])";
        if (getIt<SettingsManager>().settings.debug.skipSendingPrintJobs) {
          logWarning("Skipped sending $sheetName to $target, as sending print jobs is disabled in the debug settings");
        } else {
          logDebug("Printing $sheetName with $target");
          await _clients[printer.backend]!.printPdfToQueue(printer.queueId, sheetName, pdfData, media: printer.media);
          onSent();
          getIt<StatsManager>().addPrintedPhoto(size: size);
        }

        printedSheets.add({
          'copy': copy,
          'printer': printer.label,
          'backend': printer.backend.name,
          'queue': printer.queueId,
          'media': printer.media.toJson(),
          'margins': route.margins.toJson(),
          'layout': route.layout?.toJson(),
        });
      }
    }
  }

  /// Keeps the sheets that could be rendered. Never throws, so it does not hide why a print failed.
  Future<void> _keepPrintedPdfs(String jobName, PrintSize size, Iterable<Future<Uint8List>> renderings, List<Map<String, Object?>> printedSheets) async {
    try {
      await _writePrintedPdfs(jobName, size, renderings, printedSheets);
    } catch (error, stackTrace) {
      logError("Could not keep the PDFs of print job $jobName", error, stackTrace);
    }
  }

  Future<void> _writePrintedPdfs(String jobName, PrintSize size, Iterable<Future<Uint8List>> renderings, List<Map<String, Object?>> printedSheets) async {
    final pdfs = [
      for (final rendering in renderings) ?await rendering.then<Uint8List?>((pdf) => pdf, onError: (_) => null),
    ];
    if (pdfs.isEmpty) return;

    final outputDir = getIt<ProjectManager>().getOutputDir();
    await writeBytesToFileLocked(path.join(outputDir.path, 'latest-print.pdf'), pdfs.last);

    if (!getIt<SettingsManager>().settings.debug.enableExtensivePrintJobLog) return;
    final printJobDirectory = Directory(path.join(outputDir.path, 'PrintJobs'));
    if (!printJobDirectory.existsSync()) printJobDirectory.createSync();

    final printJobPath = path.join(printJobDirectory.path, DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()));
    for (final (index, pdf) in pdfs.indexed) {
      await File('${printJobPath}_$index.pdf').writeAsBytes(pdf);
    }
    await File('$printJobPath.json').writeAsString(jsonEncode({
      'taskName': jobName,
      'printSize': size.name,
      'sheets': printedSheets,
    }));
  }

}
