import 'dart:io';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:path/path.dart' as path;

/// Abstract class for printing systems. This assumes every printing system allows setting multiple printers. As such it wil automatically cycle through the printers when picking a printer for a new job.
abstract class PrintingSystemClient with UiLoggy {

  int lastUsedPrinterIndex = -1;

  Future<List<PrintQueueInfo>> getPrintQueues();

  Future<List<PrintQueueInfo>> getSelectedPrintQueues();

  Future<void> printPdfToQueue(String queueId, String taskName, Uint8List pdfData);

  Future<void> printPdf(String taskName, Uint8List pdfData) async {
    final printers = await getSelectedPrintQueues();
    if (printers.isEmpty) throw PrintingException('No valid printers selected');

    if (++lastUsedPrinterIndex >= printers.length) lastUsedPrinterIndex = 0;
    final PrintQueueInfo printer = printers[lastUsedPrinterIndex];

    loggy.debug("Printing with printer #${lastUsedPrinterIndex + 1} [${printer.name}]");

    await printPdfToQueue(printer.id, taskName, pdfData);

    StatsManager.instance.addPrintedPhoto();

    Directory outputDir = Directory(SettingsManager.instance.settings.output.localFolder);
    final filePath = path.join(outputDir.path, 'latest-print.pdf');
    await writeBytesToFileLocked(filePath, pdfData);
  }

}
