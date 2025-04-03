// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

typedef MapDeserializer<TData> = TData Function(Map<String, dynamic> map);

class UpdateRecord {
  final String path;
  final dynamic oldValue;
  final dynamic newValue;

  UpdateRecord({required this.path, required this.oldValue, required this.newValue});
}

/// File backed repository for a single TOML encodable and decodable value.
class TomlSerializableRepository<TData extends TomlEncodableValue> with Logger implements SerialiableRepository<TData> {

  final File file;
  final MapDeserializer<TData> deserializer;

  TomlSerializableRepository(String filePath, this.deserializer) : file = File(filePath) {
    logDebug("File path: $filePath");
  }

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

  Map<String, dynamic> getMapFromString(String tomlString) {
    TomlDocument tomlDocument = TomlDocument.parse(tomlString);
    return tomlDocument.toMap();
  }

  Future<Map<String, dynamic>> getMapFromFile(File file) async {
    return getMapFromString(await file.readAsString());
  }

  @override
  Future<TData> get() async {
    final tomlMap = await getMapFromFile(file);
    return deserializer(tomlMap);
  }

  Future<(TData, List<UpdateRecord>)> overlayWithMap(Map<String, dynamic> overlayTomlMap) async {
    final baseTomlMap = await getMapFromFile(file);
    final (merged, updates) = overlayMaps(baseTomlMap, overlayTomlMap);
    return (deserializer(merged), updates);
  }

  Future<Future<(TData, List<UpdateRecord>)>> overlayWith(TomlSerializableRepository<TData> overlayOb) async {
    return overlayWithMap(await getMapFromFile(overlayOb.file));
  }

  /// Merges two nested maps, with the [overlay] taking precedence over the [base].
  ///
  /// The function supports an optional [allowlist], where entries act as globs,
  /// meaning any specified key path applies to all possible sub-paths.
  ///
  /// Additionally, it keeps track of updated paths, storing the old and new values.
  ///
  /// @param base The base map to be merged into.
  /// @param overlay The overlay map, whose values take precedence.
  /// @param allowlist (Optional) A set of key paths that determine which keys
  ///        from the overlay are applied. Paths act as prefixes for sub-paths.
  /// @return A tuple containing the merged map and a list of updated paths with old and new values.
  (Map<String, dynamic>, List<UpdateRecord>) overlayMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
    {Set<String>? allowlist}
  ) {
    Map<String, dynamic> result = Map.from(base);
    List<UpdateRecord> updates = [];

    void merge(Map<String, dynamic> target, Map<String, dynamic> source, String currentPath) {
      source.forEach((key, value) {
        String newPath = currentPath.isEmpty ? key : '$currentPath.$key';
        bool isAllowed = allowlist == null || allowlist.isEmpty ||
                        allowlist.any((allowedPath) => newPath.startsWith(allowedPath));
        if (!isAllowed) {
          return; // Skip keys not in allowlist
        }

        if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
          merge(target[key], value, newPath);
        } else {
          if (target.containsKey(key)) {
            updates.add(UpdateRecord(path: newPath, oldValue: target[key], newValue: value));
          }
          target[key] = value;
        }
      });
    }

    merge(result, overlay, "");
    return (result, updates);
  }

  @override
  Future<void> delete() async => await file.delete();

}
