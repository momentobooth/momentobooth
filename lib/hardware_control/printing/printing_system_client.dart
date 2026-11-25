import 'dart:typed_data';

import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/utils/logger.dart';

/// A printing backend. Which printer gets which job is decided by the print routing graph, so a client only sends a
/// job to the queue it is given.
abstract class PrintingSystemClient with Logger {

  Future<List<PrintQueueInfo>> getPrintQueues();

  Future<void> printPdfToQueue(String queueId, String jobName, Uint8List pdfData, {required PrintMedia media});

  /// Prints the PDF [render] makes, given the margins the printer driver reports for the page in mm. Backends that do
  /// not know these margins pass null.
  Future<void> printLayoutToQueue(
    String queueId,
    String jobName, {
    required PrintMedia media,
    required Future<Uint8List> Function(PrintMargins? driverMargins) render,
  }) async => printPdfToQueue(queueId, jobName, await render(null), media: media);

}
