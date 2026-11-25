import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/serializable/toml_backup_repository.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:talker/talker.dart';

void main() {
  late Directory directory;
  late TomlSerializableRepository<Settings> source;
  late TomlBackupRepository<Settings> backups;

  // The repositories log through the application logger.
  setUpAll(() => getIt.registerSingleton(Talker(settings: TalkerSettings(useConsoleLogs: false))));
  tearDownAll(getIt.reset);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('toml_backup_test');
    source = TomlSerializableRepository('${directory.path}/Settings.toml', Settings.fromJson);
    backups = TomlBackupRepository(source: source, directory: Directory('${directory.path}/Backups'), maxBackups: 2);
  });

  tearDown(() => directory.delete(recursive: true));

  test('file names round trip', () {
    final createdAt = DateTime(2026, 11, 25, 14, 30, 5);
    final name = ConfigBackup.fileName(createdAt, '0.17.0+123', ConfigBackupReason.unsupportedValues);
    final backup = ConfigBackup.fromFile(File(name))!;

    expect(name, '2026-11-25_14-30-05_v0.17.0+123_unsupported-values.toml');
    expect(backup.createdAt, createdAt);
    expect(backup.appVersion, '0.17.0+123');
    expect(backup.reason, ConfigBackupReason.unsupportedValues);
    expect(ConfigBackup.fromFile(File('notes.toml')), isNull);
  });

  group('backUpOnStartup', () {
    test('does nothing without a file', () async {
      final result = await backups.backUpOnStartup(appVersion: '1.0.0+1');

      expect(result.backup, isNull);
      expect(await backups.list(), isEmpty);
    });

    test('backs up once per version', () async {
      await source.write(Settings.withDefaults());

      expect((await backups.backUpOnStartup(appVersion: '1.0.0+1')).backup?.reason, ConfigBackupReason.newVersion);
      expect((await backups.backUpOnStartup(appVersion: '1.0.0+1')).backup, isNull);
      expect((await backups.backUpOnStartup(appVersion: '1.1.0+2')).backup?.reason, ConfigBackupReason.newVersion);
    });

    test('backs up settings unknown to this version', () async {
      await source.write(Settings.withDefaults());
      await backups.backUpOnStartup(appVersion: '1.0.0+1');
      // Prepended, as appended keys would end up in the last table.
      await source.file.writeAsString('removedSetting = 1\n${await source.file.readAsString()}');

      final result = await backups.backUpOnStartup(appVersion: '1.0.0+1');

      expect(result.backup?.reason, ConfigBackupReason.unsupportedValues);
      expect(result.unsupportedPaths, ['removedSetting']);
      expect(await result.backup!.file.readAsString(), await source.file.readAsString());
    });

    test('backs up a file that cannot be read', () async {
      await source.file.writeAsString('this is = = not toml');

      final result = await backups.backUpOnStartup(appVersion: '1.0.0+1');

      expect(result.backup?.reason, ConfigBackupReason.unreadable);
    });

    test('does not back up an unchanged unreadable file again', () async {
      await source.file.writeAsString('this is = = not toml');
      await backups.backUpOnStartup(appVersion: '1.0.0+1');

      expect((await backups.backUpOnStartup(appVersion: '1.0.0+1')).backup, isNull);
      await source.file.writeAsString('this is = = still not toml');
      expect((await backups.backUpOnStartup(appVersion: '1.0.0+1')).backup?.reason, ConfigBackupReason.unreadable);
    });
  });

  test('keeps only the newest backups', () async {
    await source.write(Settings.withDefaults());
    await backups.directory.create();
    for (final day in [1, 2]) {
      await File('${backups.directory.path}/${ConfigBackup.fileName(DateTime(2020, 1, day), '1.0.0+1', ConfigBackupReason.manual)}').create();
    }

    final created = await backups.create(ConfigBackupReason.manual, appVersion: '1.0.0+1');

    expect((await backups.list()).map((b) => b.createdAt), [created!.createdAt, DateTime(2020, 1, 2)]);
  });
}
