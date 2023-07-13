class PhotoCaptureException implements Exception {

  final String message;
  final String captureImplementationName;

  PhotoCaptureException(this.message, {required this.captureImplementationName});

  factory PhotoCaptureException.fromImplementationRuntimeType(
    String message,
    Object photoCaptureImplementationInstance,
  ) =>
      PhotoCaptureException(
        message,
        captureImplementationName: photoCaptureImplementationInstance.runtimeType.toString(),
      );

  @override
  String toString() => "$message (Implementation: $captureImplementationName)";

}
