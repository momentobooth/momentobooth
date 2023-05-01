
import 'dart:io';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:path/path.dart';
import 'package:printing/printing.dart';

Future<Printer?> getSelectedPrinter() async {
  // Find printer that was set in settings in available printers.
  final printers = await Printing.listPrinters();
  Printer? selected;
  for (var printer in printers) {
    if (printer.name == SettingsManagerBase.instance.settings.hardware.printerName) {
      selected = printer;
      break;
    }
  }
  if (selected == null) {
      Loggy<UiLoggy>("hardware utils").error("Could not find selected printer");
  }
  return selected;
}

Future<bool> printPDF(Uint8List pdfData) async {
  final settings = SettingsManagerBase.instance.settings.hardware;
  final printer = await getSelectedPrinter();
  if (printer == null) return false;

  bool success = await Printing.directPrintPdf(
      printer: printer,
      name: "MomentoBooth image",
      onLayout: (pageFormat) => pdfData,
      usePrinterSettings: settings.usePrinterSettings,
  );
  StatsManagerBase.instance.addPrintedPhoto();
  
  Directory outputDir = Directory(SettingsManagerBase.instance.settings.output.localFolder);
  final filePath = join(outputDir.path, 'latest-print.pdf');
  File file = await File(filePath).create();
  await file.writeAsBytes(pdfData);

  return success;
}
