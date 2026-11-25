import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:talker/talker.dart';

void main() {
  late Directory directory;
  late TomlSerializableRepository<Settings> repository;

  // The repository logs through the application logger.
  setUpAll(() => getIt.registerSingleton(Talker(settings: TalkerSettings(useConsoleLogs: false))));
  tearDownAll(() => getIt.reset());

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('toml_repository_test');
    repository = TomlSerializableRepository('${directory.path}/Settings.toml', Settings.fromJson);
    await repository.write(Settings.withDefaults());
  });

  tearDown(() => directory.delete(recursive: true));

  group('leafPaths', () {
    test('descends into tables and arrays of tables only', () {
      final map = {
        'a': 1,
        'b': {'c': true, 'd': <String, dynamic>{}},
        'e': [1, 2],
        'f': [
          {'g': 'x'},
          {'h': 'y'},
        ],
      };

      expect(leafPaths(map), ['a', 'b.c', 'e', 'f[0].g', 'f[1].h']);
    });
  });

  group('findUnsupportedPaths', () {
    test('finds nothing in a freshly written file', () async {
      final map = await repository.getMapFromFile(repository.file);

      expect(repository.findUnsupportedPaths(map), isEmpty);
    });

    test('finds values of settings that no longer exist', () async {
      final map = await repository.getMapFromFile(repository.file);
      (map['hardware'] as Map<String, dynamic>)['removedSetting'] = 1;
      map['removedSection'] = {'value': 'x'};

      expect(repository.findUnsupportedPaths(map), unorderedEquals(['hardware.removedSetting', 'removedSection.value']));
    });
  });

  group('overlayWithMap', () {
    test('reports changed, unchanged and unsupported values', () async {
      final result = await repository.overlayWithMap({
        'hardware': {
          'liveViewFlip': 'vertically',
          'captureFlip': 'none',
          'removedSetting': 1,
        },
        'removedSection': {'value': 'x'},
      });

      final updatesByPath = {for (final update in result.updates) update.path: update};
      expect(updatesByPath.keys, unorderedEquals(['hardware.liveViewFlip', 'hardware.captureFlip']));
      expect(updatesByPath['hardware.liveViewFlip']!.isChanged, isTrue);
      expect(updatesByPath['hardware.captureFlip']!.isChanged, isFalse);
      expect(result.unsupportedPaths, unorderedEquals(['hardware.removedSetting', 'removedSection.value']));
      expect(result.data.hardware.liveViewFlip, Flip.vertically);
    });
  });
}
