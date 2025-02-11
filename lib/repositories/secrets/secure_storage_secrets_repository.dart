import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';

/// A [SecretsRepository] that uses [FlutterSecureStorage] to store secrets.
class SecureStorageSecretsRepository extends SecretsRepository {

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  const SecureStorageSecretsRepository();

  @override
  Future<void> storeSecret(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> getSecret(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> deleteSecret(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> clearSecrets() async {
    await _secureStorage.deleteAll();
  }

}
