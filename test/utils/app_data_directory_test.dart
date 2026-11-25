import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/utils/app_data_directory.dart';

void main() {
  group('seedAppDataDirectory', () {
    late Directory root;
    late Directory defaultDirectory;
    late String overridePath;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('app_data_directory_test');
      defaultDirectory = await Directory('${root.path}/default').create();
      overridePath = '${root.path}/override/nested';
      await File('${defaultDirectory.path}/Settings.toml').writeAsString('a = 1');
      await File('${defaultDirectory.path}/Projects.toml').writeAsString('b = 2');
      await File('${defaultDirectory.path}/Stats.toml').writeAsString('c = 3');
    });

    tearDown(() => root.delete(recursive: true));

    test('copies the configuration into a new directory', () async {
      final copied = await seedAppDataDirectory(from: defaultDirectory.path, to: overridePath);

      expect(copied, ['Settings.toml', 'Projects.toml']);
      expect(await File('$overridePath/Settings.toml').readAsString(), 'a = 1');
      expect(File('$overridePath/Stats.toml').existsSync(), isFalse);
    });

    test('keeps files that already exist', () async {
      await Directory(overridePath).create(recursive: true);
      await File('$overridePath/Settings.toml').writeAsString('a = 9');

      final copied = await seedAppDataDirectory(from: defaultDirectory.path, to: overridePath);

      expect(copied, ['Projects.toml']);
      expect(await File('$overridePath/Settings.toml').readAsString(), 'a = 9');
    });
  });
}
