import 'dart:io';

import 'package:collection/collection.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

/// Why a backup of a configuration file was made. The [id] is part of the backup file name.
enum ConfigBackupReason {

  newVersion('new-version', 'New version started'),
  unsupportedValues('unsupported-values', 'Settings unknown to this version'),
  unreadable('unreadable', 'Could not be read'),
  beforeImport('before-import', 'Before import or restore'),
  manual('manual', 'Created manually');

  final String id;
  final String description;

  const ConfigBackupReason(this.id, this.description);

}

/// A backup of a configuration file, see [TomlBackupRepository].
class ConfigBackup {

  final File file;
  final DateTime createdAt;

  /// The version of the application that made the backup, e.g. `0.17.0+123`.
  final String appVersion;
  final ConfigBackupReason reason;

  const ConfigBackup({required this.file, required this.createdAt, required this.appVersion, required this.reason});

  static final RegExp _fileNamePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})_v(.+)_([a-z-]+)\.toml$');

  static String fileName(DateTime createdAt, String appVersion, ConfigBackupReason reason) {
    String two(int value) => value.toString().padLeft(2, '0');
    String date = '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)}';
    String time = '${two(createdAt.hour)}-${two(createdAt.minute)}-${two(createdAt.second)}';
    return '${date}_${time}_v${appVersion}_${reason.id}.toml';
  }

  /// Parses a backup from its file name, or returns null if the name is not one made by [fileName].
  static ConfigBackup? fromFile(File file) {
    RegExpMatch? match = _fileNamePattern.firstMatch(path.basename(file.path));
    if (match == null) return null;

    ConfigBackupReason? reason = ConfigBackupReason.values.firstWhereOrNull((r) => r.id == match.group(8));
    if (reason == null) return null;

    List<int> parts = [for (int i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return ConfigBackup(
      file: file,
      createdAt: DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]),
      appVersion: match.group(7)!,
      reason: reason,
    );
  }

}

/// The outcome of [TomlBackupRepository.backUpOnStartup].
typedef StartupBackupResult = ({
  /// The backup that was made, if any.
  ConfigBackup? backup,

  /// The paths of values in the configuration file that this version of the application does not use. These are
  /// lost the next time the file is saved.
  List<String> unsupportedPaths,
});

/// Keeps timestamped copies of the file of a [TomlSerializableRepository] in [directory], so configuration that gets
/// lost (e.g. because a newer version no longer has a setting) can be looked up and restored.
class TomlBackupRepository<TData extends TomlEncodableValue> with Logger {

  final TomlSerializableRepository<TData> source;
  final Directory directory;

  /// How many backups are kept. When a new backup is made, the oldest ones beyond this number are removed.
  final int maxBackups;

  TomlBackupRepository({required this.source, required this.directory, this.maxBackups = 30});

  /// Returns all backups, newest first.
  Future<List<ConfigBackup>> list() async {
    if (!directory.existsSync()) return [];
    return directory
        .listSync()
        .whereType<File>()
        .map(ConfigBackup.fromFile)
        .nonNulls
        .sorted((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Copies the current file of [source] to a new backup, or returns null when the file does not exist.
  Future<ConfigBackup?> create(ConfigBackupReason reason, {required String appVersion}) async {
    if (!source.file.existsSync()) return null;

    await directory.create(recursive: true);
    DateTime now = DateTime.now();
    File target = File(path.join(directory.path, ConfigBackup.fileName(now, appVersion, reason)));
    await source.file.copy(target.path);
    logInfo("Backed up ${path.basename(source.file.path)} to ${target.path} (${reason.description})");

    await _removeOldBackups();
    return ConfigBackup.fromFile(target);
  }

  /// Makes a backup before the file of [source] is loaded, when the file contains values that this version does not
  /// use (they would be lost on the next save), cannot be read, or was last backed up by another version.
  Future<StartupBackupResult> backUpOnStartup({required String appVersion}) async {
    if (!source.file.existsSync()) return (backup: null, unsupportedPaths: const <String>[]);

    List<String> unsupportedPaths;
    ConfigBackupReason? reason;
    try {
      unsupportedPaths = source.findUnsupportedPaths(await source.getMapFromFile(source.file));
      if (unsupportedPaths.isNotEmpty) reason = ConfigBackupReason.unsupportedValues;
    } catch (e) {
      logWarning("Could not analyze ${source.file.path}: $e");
      unsupportedPaths = const [];
      reason = ConfigBackupReason.unreadable;
    }

    if (reason == null) {
      ConfigBackup? latest = (await list()).firstOrNull;
      if (latest?.appVersion != appVersion) reason = ConfigBackupReason.newVersion;
    }

    ConfigBackup? backup = reason != null ? await create(reason, appVersion: appVersion) : null;
    return (backup: backup, unsupportedPaths: unsupportedPaths);
  }

  Future<void> _removeOldBackups() async {
    for (ConfigBackup backup in (await list()).skip(maxBackups)) {
      await backup.file.delete();
    }
  }

}
