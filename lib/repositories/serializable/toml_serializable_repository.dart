// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

typedef MapDeserializer<TData> = TData Function(Map<String, dynamic> map);

/// File backed repository for a single TOML encodable and decodable value.
class TomlSerializableRepository<TData extends TomlEncodableValue> implements SerialiableRepository<TData> {

  final File file;
  final MapDeserializer<TData> deserializer;

  TomlSerializableRepository(String filePath, this.deserializer) : file = File(filePath);

  @override
  Future<bool> hasExistingData() async => await file.exists();

  @override
  Future<void> write(TData dataObject) async {
    // Create directory if not existing.
    String fileDirectoryName = path.dirname(file.path);
    Directory fileDirectory = Directory(fileDirectoryName);
    await fileDirectory.create(recursive: true);

    Map<String, dynamic> tomlMap = dataObject.toTomlValue();
    TomlDocument tomlDocument = TomlDocument.fromMap(tomlMap);
    String tomlString = tomlDocument.toString();

    await file.writeAsString(tomlString);
  }

  @override
  Future<TData> get() async {
    String tomlString = await file.readAsString();
    TomlDocument tomlDocument = TomlDocument.parse(tomlString);
    Map<String, dynamic> tomlMap = tomlDocument.toMap();

    return deserializer(tomlMap);
  }

  @override
  Future<void> delete() async => await file.delete();

}
