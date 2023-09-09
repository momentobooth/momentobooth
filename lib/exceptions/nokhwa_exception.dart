class NokhwaException implements Exception {

  final String message;

  NokhwaException(this.message);

  @override
  String toString() => message;

}
