import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;

/// Abstract class for printing systems. This assumes every printing system allows setting multiple printers. As such it wil automatically cycle through the printers when picking a printer for a new job.
abstract class PrintingSystemClient with Logger {

  int lastUsedPrinterIndex = -1;

  Future<List<PrintQueueInfo>> getPrintQueues();

  Future<List<PrintQueueInfo>> getSelectedPrintQueues();

  Future<void> printPdfToQueue(String queueId, String taskName, Uint8List pdfData, {PrintSize printSize = PrintSize.normal});

  Future<void> printPdf(String taskName, Uint8List pdfData, {int copies=1, PrintSize printSize = PrintSize.normal}) async {
    final printers = await getSelectedPrintQueues();
    if (printers.isEmpty) throw PrintingException('No valid printers selected');

    List<String> usedPrinters = [];
    for (int i = 0; i < copies; i++) {
      if (++lastUsedPrinterIndex >= printers.length) lastUsedPrinterIndex = 0;
      final PrintQueueInfo printer = printers[lastUsedPrinterIndex];

      logDebug("Printing $taskName at ${printSize.name}, copy #${i+1} / $copies with printer #${lastUsedPrinterIndex + 1} [${printer.name}]");
      usedPrinters.add(printer.name);

      final String jobName = "$taskName | ${printSize.name} | copy ${i+1} / $copies";
      await printPdfToQueue(printer.id, jobName, pdfData, printSize: printSize);

      getIt<StatsManager>().addPrintedPhoto(size: printSize);
    }

    if (getIt<SettingsManager>().settings.debug.enableExtensivePrintJobLog) {
      String dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String printJobDirPath = path.join(getIt<ProjectManager>().getOutputDir().path, 'PrintJobs');

      Directory printJobDirectory = Directory(printJobDirPath);
      if (!printJobDirectory.existsSync()) printJobDirectory.createSync();

      String printJobPath = path.join(printJobDirPath, dateStr);

      await File('$printJobPath.pdf').writeAsBytes(pdfData);
      await File('$printJobPath.json').writeAsString(jsonEncode({
        'taskName': taskName,
        'printers': usedPrinters,
        'printSize': printSize.toString(),
      }));
    }
  }

}
