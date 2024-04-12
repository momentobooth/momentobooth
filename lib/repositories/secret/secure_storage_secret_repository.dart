import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momento_booth/repositories/secret/secret_repository.dart';

/// A [SecretRepository] that uses [FlutterSecureStorage] to store secrets.
class SecureStorageSecretRepository extends SecretRepository {

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  const SecureStorageSecretRepository();

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
