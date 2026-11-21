class PrintingException implements Exception {

  final String message;

  /// The sheets that were sent to printers before printing failed. Guests may get those prints.
  final int sentSheets;

  PrintingException(this.message, {this.sentSheets = 0});

  @override
  String toString() => message;

}
