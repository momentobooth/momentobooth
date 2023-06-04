
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

int lastUsedPrinterIndex = -1;

Future<Uint8List> getImagePDF(Uint8List imageData) async {
  late final pw.MemoryImage image = pw.MemoryImage(imageData);
  const mm = PdfPageFormat.mm;
  final settings = SettingsManagerBase.instance.settings.hardware;
  final pageFormat = PdfPageFormat(settings.pageWidth * mm, settings.pageHeight * mm,
                                    marginBottom: settings.printerMarginBottom * mm,
                                    marginLeft: settings.printerMarginLeft * mm,
                                    marginRight: settings.printerMarginRight * mm,
                                    marginTop: settings.printerMarginTop * mm,);
  const fit = pw.BoxFit.contain;

  // Check if photo should be rotated
  // Do not assume any prior knowledge about the image.
  final bool rotate = image.width! > image.height!;
  late final pw.Image imageWidget;
  if (rotate) {
    imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableWidth, width: pageFormat.availableHeight);
  } else {
    imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableHeight, width: pageFormat.availableWidth);
  }

  final doc = pw.Document(title: "MomentoBooth image");
  doc.addPage(pw.Page(
    pageFormat: pageFormat,
    build: (pw.Context context) {
      return pw.Center(
        child: rotate ? pw.Transform.rotateBox(angle: 0.5*pi, child: imageWidget,) : imageWidget,
      );
    })
  );

  return await doc.save();
}

Future<List<Printer>> getSelectedPrinters() async {
  // Find printer that was set in settings in available printers.
  final sourcePrinters = await Printing.listPrinters();
  List<Printer> printers = <Printer>[];

  for (String name in SettingsManagerBase.instance.settings.hardware.printerNames) {
    Printer? selected = sourcePrinters.firstWhereOrNull((printer) => printer.name == name);
    if (selected == null) {
        Loggy<UiLoggy>("hardware utils").error("Could not find selected printer ($name)");
    }
    printers.add(selected!);
  }
  return printers;
}

Future<bool> printPDF(Uint8List pdfData) async {
  final settings = SettingsManagerBase.instance.settings.hardware;
  final printers = await getSelectedPrinters();
  if (printers.isEmpty) return false;

  if (++lastUsedPrinterIndex >= printers.length) { lastUsedPrinterIndex = 0; }
  final printer = printers[lastUsedPrinterIndex];

  Loggy<UiLoggy>("hardware utils").debug("Printing with printer #${lastUsedPrinterIndex+1} (${printer.name})");

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
