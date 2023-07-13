class LiveViewInitializationException implements Exception {

  final String message;
  final String? liveViewImplementationName;

  LiveViewInitializationException(this.message, {this.liveViewImplementationName});

  factory LiveViewInitializationException.fromImplementationRuntimeType(
    String message, [
    Object? liveViewImplementationInstance,
  ]
  ) =>
      LiveViewInitializationException(
        message,
        liveViewImplementationName: liveViewImplementationInstance.runtimeType.toString(),
      );

  @override
  String toString() => "$message (Implementation: $liveViewImplementationName)";

}
