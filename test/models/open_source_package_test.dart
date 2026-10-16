import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/models/open_source_package.dart';

Uint8List _encode(Map<String, Object?> json) => Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json))));

void main() {
  group('OpenSourcePackage.decodeAll', () {
    test('resolves shared license texts by index', () {
      final packages = OpenSourcePackage.decodeAll(_encode({
        'texts': ['MIT text', 'Apache text'],
        'packages': [
          {'name': 'a', 'ecosystem': 'dart', 'usage': 'runtime', 'isDirect': true, 'version': '1.0.0', 'license': 'MIT', 'licenseText': 0},
          {'name': 'b', 'ecosystem': 'rust', 'usage': 'runtime', 'license': 'MIT', 'licenseText': 0},
          {'name': 'c', 'ecosystem': 'flutterEngine', 'usage': 'runtime', 'licenseText': 1},
        ],
      }));

      expect(packages.map((p) => p.licenseText), ['MIT text', 'MIT text', 'Apache text']);
      expect(packages[0], const OpenSourcePackage(
        name: 'a',
        ecosystem: OpenSourceEcosystem.dart,
        usage: OpenSourceUsage.runtime,
        isDirect: true,
        version: '1.0.0',
        license: 'MIT',
        licenseText: 'MIT text',
      ));
    });

    test('defaults optional fields when they are absent', () {
      final [package] = OpenSourcePackage.decodeAll(_encode({
        'texts': <String>[],
        'packages': [
          {'name': 'Inno Setup', 'ecosystem': 'toolchain', 'usage': 'buildTime'},
        ],
      }));

      expect(package.isDirect, isFalse);
      expect(package.usage, OpenSourceUsage.buildTime);
      expect(package.version, isNull);
      expect(package.license, isNull);
      expect(package.licenseText, isNull);
    });
  });
}
