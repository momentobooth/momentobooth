class MqttException implements Exception {

  final String message;

  MqttException(this.message);

  @override
  String toString() => message;

}
