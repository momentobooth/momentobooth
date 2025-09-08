import 'dart:typed_data';

import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/logger.dart';

/// Abstract class for printing systems. This assumes every printing system allows setting multiple printers. As such it wil automatically cycle through the printers when picking a printer for a new job.
abstract class PrintingSystemClient with Logger {

  int lastUsedPrinterIndex = -1;

  Future<List<PrintQueueInfo>> getPrintQueues();

  Future<List<PrintQueueInfo>> getSelectedPrintQueues();

  Future<void> printPdfToQueue(String queueId, String taskName, Uint8List pdfData, {PrintSize printSize = PrintSize.normal});

  Future<void> printPdf(String taskName, Uint8List pdfData, {int copies=1, PrintSize printSize = PrintSize.normal}) async {
    final printers = await getSelectedPrintQueues();
    if (printers.isEmpty) throw PrintingException('No valid printers selected');

    for (int i = 0; i < copies; i++) {
      if (++lastUsedPrinterIndex >= printers.length) lastUsedPrinterIndex = 0;
      final PrintQueueInfo printer = printers[lastUsedPrinterIndex];

      logDebug("Printing $taskName at ${printSize.name}, copy #${i+1} / $copies with printer #${lastUsedPrinterIndex + 1} [${printer.name}]");

      final String jobName = "$taskName | ${printSize.name} | copy ${i+1} / $copies";
      await printPdfToQueue(printer.id, jobName, pdfData, printSize: printSize);

      getIt<StatsManager>().addPrintedPhoto(size: printSize);
    }
  }

}
