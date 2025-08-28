import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/logging.dart';
import 'package:printing/printing.dart';

/// Printing implementation that uses the flutter `printing` library to print.
/// This should work on all operating systems.
class FlutterPrintingClient extends PrintingSystemClient {

  @override
  Future<List<PrintQueueInfo>> getPrintQueues() async {
    List<Printer> printers = await Printing.listPrinters();
    return printers.map((printer) => printer.asPrintQueueInfo).toList();
  }

  Future<List<Printer>> _getSelectedPrintQueues() async {
    final sourcePrinters = await Printing.listPrinters();
    List<Printer> printers = <Printer>[];

    // Match all printers with printers set in settings.
    for (String name in getIt<SettingsManager>().settings.hardware.flutterPrintingPrinterNames) {
      Printer? selected = sourcePrinters.firstWhereOrNull((printer) => printer.name == name);

      // Ignore printers that are not available.
      if (selected == null) {
        logError("Could not find selected printer ($name)");
      } else {
        printers.add(selected);
      }
    }

    return printers;
  }

  @override
  Future<List<PrintQueueInfo>> getSelectedPrintQueues() async {
    List<Printer> selectedPrintQueues = await _getSelectedPrintQueues();
    return selectedPrintQueues.map((queue) => queue.asPrintQueueInfo).toList();
  }

  @override
  Future<void> printPdfToQueue(String queueId, String taskName, Uint8List pdfData, {PrintSize printSize = PrintSize.normal}) async {
    // Find specific printer
    final printers = await _getSelectedPrintQueues();
    Printer? printer = printers.firstWhereOrNull((printer) => printer.name == queueId);
    if (printer == null) throw PrintingException('Could not find printer with name [$queueId]');

    // Print
    final settings = getIt<SettingsManager>().settings.hardware;
    bool success = await Printing.directPrintPdf(
      printer: printer,
      name: taskName,
      onLayout: (pageFormat) => pdfData,
      usePrinterSettings: settings.usePrinterSettings,
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
