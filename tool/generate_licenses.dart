// Generates assets/licenses/licenses.json.gz, the data source of the open source licenses overview on the About settings page.
//
// Sources:
// - Dart packages: pubspec.lock, via dart_pubspec_licenses (including the Flutter engine components).
// - Rust crates: rust/Cargo.lock, via `cargo metadata` and `cargo bundle-licenses`.
// - Native libraries: the manifest of the prebuilt native dependencies in .native_deps (see `just get-native-deps`), if present.
// - Other native libraries and the toolchain: licenses/manual_licenses.toml. Entries also found in the native dependencies manifest are skipped.
//
// Run with `just gen-licenses`.

import 'dart:convert';
import 'dart:io';

import 'package:dart_pubspec_licenses/dart_pubspec_licenses.dart' as oss;
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

const _outputPath = 'assets/licenses/licenses.json.gz';
const _manualLicensesPath = 'licenses/manual_licenses.toml';
const _rustProjectPath = 'rust';
const _nativeDepsPath = '.native_deps';
const _sdkLicensePrefix = 'sky_engine/';
const _rustLicenseNotFound = 'NOT FOUND';

/// Packages that are part of MomentoBooth itself and should not be listed.
const _ownPackages = {'momento_booth', 'rust_lib_momento_booth'};

Future<void> main() async {
  final texts = _LicenseTexts();
  final nativeDepsPackages = await _nativeDepsPackages(texts);
  final packages = [
    ...await _dartPackages(texts),
    ...await _rustPackages(texts),
    ...nativeDepsPackages,
    ...await _manualPackages(texts, skip: {for (final package in nativeDepsPackages) package['name']! as String}),
  ]..sort((a, b) => (a['name']! as String).toLowerCase().compareTo((b['name']! as String).toLowerCase()));

  final outputFile = File(_outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(GZipCodec(level: 9).encode(utf8.encode(jsonEncode({'texts': texts.all, 'packages': packages}))));

  stdout.writeln('Wrote ${packages.length} packages with ${texts.all.length} unique license texts to $_outputPath');
}

/// Deduplicates license texts, as many packages share the exact same text.
class _LicenseTexts {

  final List<String> all = [];
  final Map<String, int> _indexByText = {};

  int? add(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return _indexByText.putIfAbsent(text, () {
      all.add(text);
      return all.length - 1;
    });
  }

}

Map<String, Object?> _entry({
  required String name,
  required String ecosystem,
  required String usage,
  bool isDirect = false,
  String? version,
  String? description,
  String? url,
  String? license,
  int? licenseText,
}) {
  return {
    'name': name,
    'ecosystem': ecosystem,
    'usage': usage,
    'isDirect': isDirect,
    'version': ?version,
    'description': ?_nullIfBlank(description),
    'url': ?_nullIfBlank(url),
    'license': ?_nullIfBlank(license),
    'licenseText': ?licenseText,
  };
}

String? _nullIfBlank(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

// ////////////// //
// Dart packages  //
// ////////////// //

Future<List<Map<String, Object?>>> _dartPackages(_LicenseTexts texts) async {
  final structure = await oss.listDependencies(
    pubspecYamlPath: 'pubspec.yaml',
    ignore: _ownPackages.toList(),
    splitSdkLicenses: true,
  );
  final root = structure.package;

  // Everything reachable from the regular dependencies ends up in the application, the rest is only used at build time.
  final runtimeNames = <String>{};
  void collectRuntime(oss.Package package) {
    if (!runtimeNames.add(package.name)) return;
    package.dependencies.forEach(collectRuntime);
  }
  root.dependencies.forEach(collectRuntime);

  final directNames = {...root.dependencies.map((p) => p.name), ...root.devDependencies.map((p) => p.name)};
  final flutterLicense = structure.allDependencies.where((p) => p.name == 'flutter').firstOrNull?.license;

  return [
    for (final package in structure.allDependencies)
      if (package.name.startsWith(_sdkLicensePrefix))
        _entry(
          name: package.name.substring(_sdkLicensePrefix.length),
          ecosystem: 'flutterEngine',
          usage: 'runtime',
          license: package.spdxIdentifiers.join(' AND '),
          licenseText: texts.add(package.license),
        )
      else
        _entry(
          name: package.name,
          ecosystem: 'dart',
          usage: runtimeNames.contains(package.name) ? 'runtime' : 'buildTime',
          isDirect: directNames.contains(package.name),
          version: package.version,
          description: package.description,
          url: package.homepage ?? package.repository,
          license: package.spdxIdentifiers.join(' AND '),
          // Flutter SDK packages like flutter_localizations do not ship a license file of their own.
          licenseText: texts.add(package.license?.trim().isNotEmpty == true || !package.isSdk ? package.license : flutterLicense),
        ),
  ];
}

// ////////////// //
// Rust crates    //
// ////////////// //

Future<List<Map<String, Object?>>> _rustPackages(_LicenseTexts texts) async {
  final metadata = jsonDecode(await _run('cargo', ['metadata', '--format-version', '1', '--locked'])) as Map<String, dynamic>;
  final metadataPackages = {
    for (final package in (metadata['packages'] as List).cast<Map<String, dynamic>>()) package['id'] as String: package,
  };

  // Direct dependencies are the regular (non-dev, non-build) dependencies of the helper library.
  final resolve = metadata['resolve'] as Map<String, dynamic>;
  final rootId = resolve['root'] as String;
  final rootNode = (resolve['nodes'] as List).cast<Map<String, dynamic>>().firstWhere((node) => node['id'] == rootId);
  final directIds = {
    for (final dep in (rootNode['deps'] as List).cast<Map<String, dynamic>>())
      if ((dep['dep_kinds'] as List).cast<Map<String, dynamic>>().any((kind) => kind['kind'] == null)) dep['pkg'] as String,
  };

  final bundleFile = File(path.join('.dart_tool', 'momento_booth', 'rust_licenses.json'));
  await bundleFile.parent.create(recursive: true);
  await _run('cargo', ['bundle-licenses', '--format', 'json', '--output', bundleFile.absolute.path]);
  final bundle = jsonDecode(await bundleFile.readAsString()) as Map<String, dynamic>;

  final licenseTextsByCrate = {
    for (final library in (bundle['third_party_libraries'] as List).cast<Map<String, dynamic>>())
      '${library['package_name']}@${library['package_version']}': [
        for (final license in (library['licenses'] as List).cast<Map<String, dynamic>>())
          if (license['text'] != _rustLicenseNotFound) license['text'] as String,
      ].join('\n\n${'-' * 80}\n\n'),
  };

  return [
    for (final package in metadataPackages.values)
      if (!_ownPackages.contains(package['name']))
        _entry(
          name: package['name'],
          ecosystem: 'rust',
          usage: 'runtime',
          isDirect: directIds.contains(package['id']),
          version: package['version'],
          description: package['description'],
          url: package['homepage'] ?? package['repository'],
          license: package['license'],
          licenseText: texts.add(licenseTextsByCrate['${package['name']}@${package['version']}']),
        ),
  ];
}

Future<String> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments, workingDirectory: _rustProjectPath, stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    throw ProcessException(executable, arguments, result.stderr.toString(), result.exitCode);
  }
  return result.stdout as String;
}

// ////////////////////////////////// //
// Native libraries and toolchain     //
// ////////////////////////////////// //

Future<List<Map<String, Object?>>> _nativeDepsPackages(_LicenseTexts texts) async {
  final directory = Directory(_nativeDepsPath);
  if (!directory.existsSync()) return const [];

  final packages = [
    for (final manifestFile in directory.listSync().whereType<Directory>().map((d) => File(path.join(d.path, 'manifest.json'))))
      if (manifestFile.existsSync())
        for (final component in ((jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>)['components'] as List)
            .cast<Map<String, dynamic>>())
          _entry(
            name: component['name'],
            // Build tools in the bundle, like pkgconf, are not shipped with the application.
            ecosystem: component['usage'] == 'runtime' ? 'native' : 'toolchain',
            usage: component['usage'],
            version: component['version'],
            description: component['description'],
            url: component['url'],
            license: component['license'],
            licenseText: texts.add([
              for (final licenseFile in (component['licenseFiles'] as List).cast<String>())
                await File(path.join(manifestFile.parent.path, licenseFile)).readAsString(),
            ].join('\n\n${'-' * 80}\n\n')),
          ),
  ];

  // There may be bundles for multiple architectures (e.g. on macOS), which contain the same components.
  return {for (final package in packages) package['name']: package}.values.toList();
}

Future<List<Map<String, Object?>>> _manualPackages(_LicenseTexts texts, {required Set<String> skip}) async {
  final manual = (await TomlDocument.load(_manualLicensesPath)).toMap();

  Future<List<Map<String, Object?>>> parse(String key, {required String ecosystem, required String usage}) async {
    return [
      for (final item in (manual[key] as List? ?? []).cast<Map<String, dynamic>>())
        if (!skip.contains(item['name']))
          _entry(
            name: item['name'],
            ecosystem: ecosystem,
            usage: usage,
            description: item['description'],
            url: item['url'],
            license: item['license'],
            licenseText: item['license_file'] == null
                ? null
                : texts.add(await File(path.join(path.dirname(_manualLicensesPath), item['license_file'])).readAsString()),
          ),
    ];
  }

  return [
    ...await parse('native', ecosystem: 'native', usage: 'runtime'),
    ...await parse('toolchain', ecosystem: 'toolchain', usage: 'buildTime'),
  ];
}
