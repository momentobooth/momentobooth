import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Printing implementation that uses the flutter `printing` library to print.
/// This should work on all operating systems.
class FlutterPrintingClient extends PrintingSystemClient {

  @override
  Future<List<PrintQueueInfo>> getPrintQueues() async {
    List<Printer> printers = await Printing.listPrinters();
    return printers.map((printer) => printer.asPrintQueueInfo).toList();
  }

  /// Whether this platform lists the papers of a printer, see [getPrinterMediaDimensions]. Only Windows does.
  Future<bool> canListPrinterMedia() async => (await Printing.info()).canListPaperSizes;

  /// The papers the driver of printer [printerName] supports, with their paper number as keyword and their size in mm.
  Future<List<PrintDimension>> getPrinterMediaDimensions(String printerName) async {
    final papers = await Printing.listPaperSizes(await _printer(printerName));
    return papers.map((paper) => paper.asPrintDimension).toList();
  }

  /// The media is part of [pdfData]; the printer driver decides how to put it on paper. When [media] was chosen from
  /// the papers of the printer, the job is printed on that paper with the other settings of the driver, e.g.
  /// borderless printing.
  @override
  Future<void> printPdfToQueue(String queueId, String jobName, Uint8List pdfData, {required PrintMedia media}) async {
    final printer = await _printer(queueId);
    final paper = await _paperOf(printer, media);

    bool success = await Printing.directPrintPdf(
      printer: printer,
      name: jobName,
      onLayout: (pageFormat) => pdfData,
      // The orientation of the paper follows the format.
      format: paper != null ? PdfPageFormat(media.widthMm * PdfPageFormat.mm, media.heightMm * PdfPageFormat.mm) : PdfPageFormat.standard,
      usePrinterSettings: getIt<SettingsManager>().settings.hardware.usePrinterSettings,
      paper: paper,
    );

    if (!success) throw PrintingException('Printing.directPrintPdf returned false');
  }

  Future<Printer> _printer(String name) async {
    final printers = await Printing.listPrinters();
    Printer? printer = printers.firstWhereOrNull((printer) => printer.name == name);
    if (printer == null) throw PrintingException('Could not find printer with name [$name]');
    return printer;
  }

  /// The paper [media] was chosen from, or null when its size was set by hand.
  Future<PrinterPaper?> _paperOf(Printer printer, PrintMedia media) async {
    if (media.name.isEmpty || !await canListPrinterMedia()) return null;

    final papers = await Printing.listPaperSizes(printer);
    final paper = papers.firstWhereOrNull((paper) => paper.id == media.name);
    if (paper == null) logWarning('Printer [${printer.name}] has no paper [${media.name}], printing without selecting a paper');
    return paper;
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

extension _PrinterPaperExtension on PrinterPaper {

  // Drivers report sizes in tenths of a mm, so rounding to that only undoes the conversion to points.
  PrintDimension get asPrintDimension {
    double toMm(double points) => (points / PdfPageFormat.mm * 10).roundToDouble() / 10;
    return PrintDimension(
      keyword: id,
      name: name,
      width: toMm(width),
      height: toMm(height),
    );
  }

}
