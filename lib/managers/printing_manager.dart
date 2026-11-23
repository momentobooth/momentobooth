import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/hardware_control/printing/print_job_runner.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/hardware_control/printing/stack_collector.dart';
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
    reaction((_) => getIt<ProjectManager>().settings.enablePrinting, (_) => _reportStatus());
    reaction((_) => getIt<ProjectManager>().path, _openCollector, fireImmediately: true);
  }

  /// The copies that wait on stacks in collect mode, kept in the project folder. Null without an open project.
  StackCollector? _collector;

  Future<void> _openCollector(Directory? projectPath) async {
    if (projectPath == null) {
      _collector = null;
      return;
    }
    final collector = StackCollector(DirectoryCollectedCopyStore(Directory(path.join(projectPath.path, 'Prints', 'Collections'))));
    try {
      await collector.load();
    } catch (error, stackTrace) {
      logError("Could not load the copies waiting on stacks from ${projectPath.path}", error, stackTrace);
    }
    _collector = collector;
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
    _reportStatus();
  }

  /// The labels of the printers that failed during the last print.
  Set<String> _failedPrinters = const {};

  @action
  void _reportStatus() {
    // Disabled until a printer is set up on this computer, or when the project does not print.
    if (!getIt<ProjectManager>().settings.enablePrinting || !_router.analysis.hasConfiguredPrinter) {
      reportSubsystemDisabled();
    } else if (_router.printableSizes.isEmpty) {
      reportSubsystemWarning(message: "Printing is enabled, but no print size reaches a configured printer. Connect a printer on the Print routing settings page.");
    } else if (_failedPrinters.isNotEmpty) {
      reportSubsystemWarning(message: "Printing failed on ${_failedPrinters.join(', ')} during the last print. Other printers took over where the print routing allows it, which is not the case for stacked copies.");
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

  late final PrintJobRunner _jobRunner = PrintJobRunner(
    sendSheet: _sendSheet,
    countPrint: (size) => getIt<StatsManager>().addPrintedPhoto(size: size),
    logError: logError,
  );

  /// Prints [copies] copies of [image] at [size], see [PrintJobRunner.run]. Throws a [PrintingException] when not every
  /// copy was printed. The rendered sheets are kept in any case.
  Future<void> printPhoto({required String jobName, required Uint8List image, required PrintSize size, int copies = 1}) async {
    final report = await _jobRunner.run(_router, jobName: jobName, image: image, size: size, copies: copies, collector: _collector);
    _failedPrinters = report.failedPrinters;
    _reportStatus();
    await _keepPrintedPdfs(jobName, size, report.renderings, report.sheets);
    if (report.failure case final failure?) throw failure;
  }

  /// Sends [pdfData] to the printer of [route]. Returns false when sending is skipped in the debug settings.
  Future<bool> _sendSheet(String sheetName, PrintRoute route, Uint8List pdfData) async {
    final printer = route.printer;
    final target = "[${printer.label}] (${printer.backend.name} queue [${printer.queueId}])";
    if (getIt<SettingsManager>().settings.debug.skipSendingPrintJobs) {
      logWarning("Skipped sending $sheetName to $target, as sending print jobs is disabled in the debug settings");
      return false;
    }
    logDebug("Printing $sheetName with $target");
    await _clients[printer.backend]!.printPdfToQueue(printer.queueId, sheetName, pdfData, media: printer.media);
    return true;
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

    final printsDir = getIt<ProjectManager>().getPrintsDir();
    await printsDir.create(recursive: true);
    await writeBytesToFileLocked(path.join(printsDir.path, 'latest-print.pdf'), pdfs.last);

    if (!getIt<SettingsManager>().settings.debug.enableExtensivePrintJobLog) return;
    final printJobDirectory = Directory(path.join(printsDir.path, 'PrintJobs'));
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
