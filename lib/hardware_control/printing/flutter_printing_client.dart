import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:printing/printing.dart';

/// Printing implementation that uses the flutter `printing` library to print.
/// This should work on all operating systems.
class FlutterPrintingClient extends PrintingSystemClient {

  @override
  Future<List<PrintQueueInfo>> getPrintQueues() async {
    List<Printer> printers = await Printing.listPrinters();
    return printers.map((printer) => printer.asPrintQueueInfo).toList();
  }

  /// The media is part of [pdfData]; the printer driver decides how to put it on paper.
  @override
  Future<void> printPdfToQueue(String queueId, String jobName, Uint8List pdfData, {required PrintMedia media}) async {
    final printers = await Printing.listPrinters();
    Printer? printer = printers.firstWhereOrNull((printer) => printer.name == queueId);
    if (printer == null) throw PrintingException('Could not find printer with name [$queueId]');

    bool success = await Printing.directPrintPdf(
      printer: printer,
      name: jobName,
      onLayout: (pageFormat) => pdfData,
      usePrinterSettings: getIt<SettingsManager>().settings.hardware.usePrinterSettings,
    );

    if (!success) throw PrintingException('Printing.directPrintPdf returned false');
  }

}

extension _PrinterExtension on Printer {

  PrintQueueInfo get asPrintQueueInfo {
    return PrintQueueInfo(
      id: name,
      name: name,
      isAvailable: isAvailable,
      isDefault: isDefault,
    );
  }

}
