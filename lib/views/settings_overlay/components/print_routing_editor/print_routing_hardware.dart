import 'package:flutter/services.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/hardware_control/printing/print_calibration.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
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

  /// Prints a calibration page on [printer], with its media named [mediaLabel], see [renderCalibrationPdf].
  Future<void> printCalibrationPage(PrinterNodeData printer, {required String mediaLabel, required double rulerLength});

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
  Future<void> printCalibrationPage(PrinterNodeData printer, {required String mediaLabel, required double rulerLength}) async {
    final logo = await rootBundle.loadString('assets/svg/logo.svg');
    final PrintingSystemClient client = switch (printer.backend) {
      PrinterBackend.native => FlutterPrintingClient(),
      PrinterBackend.cups => CupsClient(),
    };
    await client.printLayoutToQueue(
      printer.queueId,
      'MomentoBooth calibration page',
      media: printer.media,
      render: (driverMargins) => renderCalibrationPdf(
        printer: printer,
        mediaLabel: mediaLabel,
        rulerLength: rulerLength,
        driverMargins: driverMargins,
        logoSvg: logo,
        printedAt: DateTime.now(),
      ),
    );
  }

}
