class DefaultSettingRestoreException implements Exception {

  final String message;

  DefaultSettingRestoreException(this.message);

  @override
  String toString() => message;
  
}
