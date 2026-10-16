import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';

/// The printers and media the print routing editor can choose from.
abstract interface class PrintRoutingHardware {

  Future<List<PrintQueueInfo>> listQueues(PrinterBackend backend);

  Future<List<PrintDimension>> listCupsMedia(String queueId);

}

class SystemPrintRoutingHardware implements PrintRoutingHardware {

  const SystemPrintRoutingHardware();

  @override
  Future<List<PrintQueueInfo>> listQueues(PrinterBackend backend) => switch (backend) {
    PrinterBackend.native => FlutterPrintingClient().getPrintQueues(),
    PrinterBackend.cups => CupsClient().getPrintQueues(),
  };

  @override
  Future<List<PrintDimension>> listCupsMedia(String queueId) => CupsClient().getPrinterMediaDimensions(queueId);

}
