import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';

/// The printers and media the print routing editor can choose from.
abstract interface class PrintRoutingHardware {

  Future<List<PrintQueueInfo>> listQueues(PrinterBackend backend);

  /// Whether [listMedia] lists the papers of native printers. Otherwise their media size is set by hand.
  Future<bool> canListNativeMedia();

  /// The media of queue [queueId], with their size in mm. The keyword identifies a media, see [PrintMedia.name].
  Future<List<PrintDimension>> listMedia(PrinterBackend backend, String queueId);

  /// Prints a calibration page on [printer], with its media named [mediaLabel] and the [margins] that apply to it, see
  /// [PrintingManager.printCalibrationPage].
  Future<void> printCalibrationPage(PrinterNodeData printer, {required String mediaLabel, required double rulerLength, required PrintMargins margins});

}

class SystemPrintRoutingHardware implements PrintRoutingHardware {

  const SystemPrintRoutingHardware();

  @override
  Future<List<PrintQueueInfo>> listQueues(PrinterBackend backend) => switch (backend) {
    PrinterBackend.native => FlutterPrintingClient().getPrintQueues(),
    PrinterBackend.cups => CupsClient().getPrintQueues(),
  };

  @override
  Future<bool> canListNativeMedia() => FlutterPrintingClient().canListPrinterMedia();

  @override
  Future<List<PrintDimension>> listMedia(PrinterBackend backend, String queueId) => switch (backend) {
    PrinterBackend.native => FlutterPrintingClient().getPrinterMediaDimensions(queueId),
    PrinterBackend.cups => CupsClient().getPrinterMediaDimensions(queueId),
  };

  @override
  Future<void> printCalibrationPage(PrinterNodeData printer, {required String mediaLabel, required double rulerLength, required PrintMargins margins}) =>
      getIt<PrintingManager>().printCalibrationPage(printer, mediaLabel: mediaLabel, rulerLength: rulerLength, margins: margins);

}
