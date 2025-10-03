const String mqttPasswordSecretKey = 'mqtt_password';
const String settingsPincodeKey = 'settings_pin';

abstract class SecretsRepository {

  const SecretsRepository();

  Future<void> storeSecret(String key, String value);

  Future<String?> getSecret(String key);

  Future<void> deleteSecret(String key);

  Future<void> clearSecrets();

}
