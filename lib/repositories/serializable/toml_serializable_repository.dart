// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

typedef MapDeserializer<TData> = TData Function(Map<String, dynamic> map);

/// A value at [path] that an overlay sets, see [TomlSerializableRepository.overlayWithMap].
class UpdateRecord {

  final String path;

  /// Whether the base had a value at [path]. When false, [oldValue] is null.
  final bool hadOldValue;
  final dynamic oldValue;
  final dynamic newValue;

  UpdateRecord({required this.path, required this.hadOldValue, required this.oldValue, required this.newValue});

  bool get isChanged => !hadOldValue || !const DeepCollectionEquality().equals(oldValue, newValue);

}

/// The result of overlaying a map on the stored data, see [TomlSerializableRepository.overlayWithMap].
typedef OverlayResult<TData> = ({
  /// The stored data with the overlay applied.
  TData data,

  /// The values the overlay sets that are used by [data].
  List<UpdateRecord> updates,

  /// The paths of values the overlay sets that are not used by [data] and are therefore ignored, e.g. because they
  /// belong to a setting that this version of the application no longer has.
  List<String> unsupportedPaths,
});

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

    await file.writeAsString(_encode(dataObject));
  }

  String _encode(TData dataObject) => TomlDocument.fromMap(dataObject.toTomlValue()).toString();

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

  /// Returns the paths of the values in [map] that get lost when the map is deserialized and serialized again, e.g.
  /// because they belong to a setting that this version of the application no longer has.
  ///
  /// Paths are dot separated, with `[]` for tables in an array, e.g. `hardware.printRoutingGraph.nodes[].id`. Array
  /// elements are not matched by position, as deserialization may add, remove or reorder them.
  List<String> findUnsupportedPaths(Map<String, dynamic> map) {
    Map<String, dynamic> roundTripped = getMapFromString(_encode(deserializer(map)));
    Set<String> supportedPaths = leafPaths(roundTripped).toSet();
    return leafPaths(map).toSet().where((p) => !supportedPaths.contains(p)).toList();
  }

  /// Applies [overlayTomlMap] on the stored data, see [overlayMaps], and reports which values it sets.
  Future<OverlayResult<TData>> overlayWithMap(Map<String, dynamic> overlayTomlMap) async {
    final baseTomlMap = await getMapFromFile(file);
    final (merged, updates) = overlayMaps(baseTomlMap, overlayTomlMap);

    final unsupportedPaths = findUnsupportedPaths(merged);
    final unsupportedPathSet = unsupportedPaths.toSet();
    bool isFullyUnsupported(UpdateRecord update) => leafPaths(update.newValue, update.path).every(unsupportedPathSet.contains);

    return (
      data: deserializer(merged),
      updates: updates.whereNot(isFullyUnsupported).toList(),
      unsupportedPaths: unsupportedPaths,
    );
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
          bool hadOldValue = target.containsKey(key);
          updates.add(UpdateRecord(path: newPath, hadOldValue: hadOldValue, oldValue: target[key], newValue: value));
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

/// Returns the paths of all leaf values in [value], prefixed with [prefix].
///
/// Tables (maps) and arrays of tables are descended into, with `[]` in the path for the elements of an array of tables
/// (so paths can repeat); any other value, including an array of other values, is a leaf. Empty tables have no leaves.
List<String> leafPaths(dynamic value, [String prefix = '']) {
  if (value is Map<String, dynamic>) {
    return [
      for (final MapEntry(:key, value: child) in value.entries)
        ...leafPaths(child, prefix.isEmpty ? key : '$prefix.$key'),
    ];
  }
  if (value is List && value.isNotEmpty && value.every((e) => e is Map<String, dynamic>)) {
    return [
      for (final element in value)
        ...leafPaths(element, '$prefix[]'),
    ];
  }
  return [prefix];
}
