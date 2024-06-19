const String mqttPasswordSecretKey = 'mqtt_password';

abstract class SecretsRepository {

  const SecretsRepository();

  Future<void> storeSecret(String key, String value);

  Future<String?> getSecret(String key);

  Future<void> deleteSecret(String key);

  Future<void> clearSecrets();

}
