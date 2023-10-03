enum CaptureState {

  idle('idle'),
  countdown('countdown'),
  capturing('capturing');

  final String mqttValue;

  const CaptureState(this.mqttValue);

}
