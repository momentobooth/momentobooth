const String mqttPasswordSecretKey = 'mqtt_password';
const String settingsPincodeKey = 'settings_pin';

/// Returns the secret key under which the API key of the OpenAI-compatible endpoint with [endpointId] is stored.
String openAiEndpointSecretKey(String endpointId) => 'openai_api_key.$endpointId';

abstract class SecretsRepository {

  const SecretsRepository();

  Future<void> storeSecret(String key, String value);

  Future<String?> getSecret(String key);

  Future<void> deleteSecret(String key);

  Future<void> clearSecrets();

}
