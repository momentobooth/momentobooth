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

  /// The print sizes users can choose. Empty when printing is disabled for the project.
  @computed
  Set<PrintSize> get printableSizes => getIt<ProjectManager>().settings.enablePrinting ? _router.printableSizes : const {};

  @computed
  bool get canPrint => printableSizes.isNotEmpty;

  /// How many photos one copy of [size] puts on paper, or null when that depends on the printer it ends up at.
  int? photosPerCopy(PrintSize size) => _router.photosPerCopy(size);

  /// The printers the routing can send jobs to, without duplicates.
  Set<String> usedQueueIds(PrinterBackend backend) => {
    for (final printer in _router.usedPrinters)
      if (printer.backend == backend) printer.queueId,
  };

  // //////// //
  // Printing //
  // //////// //

  /// Prints [copies] copies of [image] at [size]. Every copy follows its own route through the print routing graph.
  Future<void> printPhoto({required String jobName, required Uint8List image, required PrintSize size, int copies = 1}) async {
    // Within one print, every distinct sheet is rendered once.
    final Map<Object, Future<Uint8List>> renderings = {};
    final List<Map<String, Object?>> printedSheets = [];

    for (int copy = 1; copy <= copies; copy++) {
      final routes = _router.nextCopy(size);
      if (routes.isEmpty) throw PrintingException('No printer is routed for ${size.label}');

      for (final route in routes) {
        final pdfData = await (renderings[route.renderKey] ??= renderPrintPdf(image, route, split: size == PrintSize.split));
        final printer = route.printer;
        final sheetName = "$jobName | ${size.label} | copy $copy / $copies";

        logDebug("Printing $sheetName with [${printer.label}] (${printer.backend.name} queue [${printer.queueId}])");
        await _clients[printer.backend]!.printPdfToQueue(printer.queueId, sheetName, pdfData, media: printer.media);
        getIt<StatsManager>().addPrintedPhoto(size: size);

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

    await _keepPrintedPdfs(jobName, size, renderings.values, printedSheets);
  }

  Future<void> _keepPrintedPdfs(String jobName, PrintSize size, Iterable<Future<Uint8List>> renderings, List<Map<String, Object?>> printedSheets) async {
    final pdfs = await Future.wait(renderings);
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
