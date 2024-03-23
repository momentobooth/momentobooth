import 'dart:typed_data';

abstract class PrintingSystemClient {

  Future<void> printPdf(String taskName, Uint8List pdfData);

}
