class PrintingException implements Exception {

  final String message;

  PrintingException(this.message);

  @override
  String toString() => message;

}
