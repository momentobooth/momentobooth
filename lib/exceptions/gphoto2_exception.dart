class GPhoto2Exception implements Exception {

  final String message;

  GPhoto2Exception(this.message);

  @override
  String toString() => message;

}
