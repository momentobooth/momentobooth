import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/src/rust/api/cups.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';

class CupsClient extends PrintingSystemClient {

  @override
  Future<List<PrintQueueInfo>> getPrintQueues() async {
    List<IppPrinterState> cupsPrinters = await cupsGetPrinters(serverInfo: serverInfo);
    return cupsPrinters.map((printer) => PrintQueueInfo(
      id: printer.queueName,
      name: printer.description,
      isAvailable: printer.stateReason != "offline-report",
    )).toList();
  }

  @override
  Future<List<PrintQueueInfo>> getSelectedPrintQueues() async {
    final sourcePrinters = await getPrintQueues();
    List<PrintQueueInfo> printers = [];

    // Match all printers with printers set in settings.
    for (String id in getIt<SettingsManager>().settings.hardware.cupsPrinterQueues) {
      PrintQueueInfo? selected = sourcePrinters.firstWhereOrNull((printer) => printer.id == id);

      // Ignore printers that are not available.
      if (selected == null) {
        logError("Could not find selected CUPS printer [$id]");
      } else {
        printers.add(selected);
      }
    }

    return printers;
  }

  @override
  Future<void> printPdfToQueue(String queueId, String taskName, Uint8List pdfData, {PrintSize printSize = PrintSize.normal}) async {
    final printLayoutSettings = getIt<SettingsManager>().settings.hardware.printLayoutSettings;
    final String mediaSizeName = switch (printSize) {
      PrintSize.normal => printLayoutSettings.mediaSizeNormal.mediaSizeString,
      PrintSize.split => printLayoutSettings.mediaSizeSplit.mediaSizeString,
      PrintSize.small => printLayoutSettings.mediaSizeSmall.mediaSizeString,
      PrintSize.tiny => printLayoutSettings.mediaSizeTiny.mediaSizeString,
    };

    await cupsPrintJob(
      serverInfo: serverInfo,
      queueId: queueId,
      jobName: taskName,
      pdfData: pdfData,
      mediaSize: mediaSizeName,
    );
  }

  Future<List<PrintDimension>> getPrinterMediaDimensions(String queueId) async {
    return await cupsGetPrinterMediaDimensions(
      serverInfo: serverInfo,
      queueId: queueId,
    );
  }

  static CupsServerInfo get serverInfo {
    return CupsServerInfo(
      uri: getIt<SettingsManager>().settings.hardware.cupsUri,
      ignoreTlsErrors: getIt<SettingsManager>().settings.hardware.cupsIgnoreTlsErrors,
      username: getIt<SettingsManager>().settings.hardware.cupsUsername,
      password: getIt<SettingsManager>().settings.hardware.cupsPassword,
    );
  }

}
