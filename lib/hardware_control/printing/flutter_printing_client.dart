import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/printer_info.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

class FlutterPrintingClient extends PrintingSystemClient with UiLoggy {

  int lastUsedPrinterIndex = -1;

  static Future<List<PrinterInfo>> getPrintQueues() async {
    List<Printer> printers = await Printing.listPrinters();
    return printers.map((printer) => PrinterInfo(
      id: printer.name,
      name: printer.name,
      isAvailable: printer.isAvailable,
      isDefault: printer.isDefault,
    )).toList();
  }

  Future<List<Printer>> _getSelectedPrinters() async {
    final sourcePrinters = await Printing.listPrinters();
    List<Printer> printers = <Printer>[];

    // Match all printers with printers set in settings.
    for (String name in SettingsManager.instance.settings.hardware.flutterPrintingPrinterNames) {
      Printer? selected = sourcePrinters.firstWhereOrNull((printer) => printer.name == name);

      // Ignore printers that are not available.
      if (selected == null) {
        loggy.error("Could not find selected printer ($name)");
      } else {
        printers.add(selected);
      }
    }

    return printers;
  }

  @override
  Future<void> printPdf(String taskName, Uint8List pdfData) async {
    final settings = SettingsManager.instance.settings.hardware;
    final printers = await _getSelectedPrinters();
    if (printers.isEmpty) throw PrintingException('No valid printers selected');

    if (++lastUsedPrinterIndex >= printers.length) lastUsedPrinterIndex = 0;
    final printer = printers[lastUsedPrinterIndex];

    loggy.debug("Printing with printer #${lastUsedPrinterIndex + 1} (${printer.name})");

    try {
      final jobList = getJobList(printer.name);
      loggy.debug("Job list for printer ${printer.name} = $jobList");
    } catch (e) {
      loggy.error(e);
    }

    bool success = await Printing.directPrintPdf(
      printer: printer,
      name: taskName,
      onLayout: (pageFormat) => pdfData,
      usePrinterSettings: settings.usePrinterSettings,
    );
    if (!success) throw PrintingException('Printing.directPrintPdf returned false');

    StatsManager.instance.addPrintedPhoto();

    Directory outputDir = Directory(SettingsManager.instance.settings.output.localFolder);
    final filePath = path.join(outputDir.path, 'latest-print.pdf');
    File file = await File(filePath).create();
    await file.writeAsBytes(pdfData);
  }
  
}
