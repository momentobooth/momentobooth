enum HomeAssistantIntegrationType {

  sensor('sensor');

  final String mqttName;

  const HomeAssistantIntegrationType(this.mqttName);

}
