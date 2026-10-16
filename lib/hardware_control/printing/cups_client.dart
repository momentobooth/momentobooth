import 'dart:typed_data';

import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
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
  Future<void> printPdfToQueue(String queueId, String jobName, Uint8List pdfData, {required PrintMedia media}) async {
    await cupsPrintJob(
      serverInfo: serverInfo,
      queueId: queueId,
      jobName: jobName,
      pdfData: pdfData,
      mediaSize: media.name,
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
