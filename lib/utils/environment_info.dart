import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/services.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/app_version_info.dart';
import 'package:momento_booth/src/rust/api/initialization.dart' as lib_init_api;
import 'package:momento_booth/src/rust/models/version_info.dart' as lib_version_info_models;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

AppVersionInfo? _appVersionInfo;
late final PackageInfo packageInfo;
late final String appDataPath;
late final lib_version_info_models.VersionInfo helperLibraryVersionInfo;

String get exifSoftwareName => '${packageInfo.appName} ${packageInfo.version} build ${packageInfo.buildNumber} ($osFriendlyName)';

String get osFriendlyName => switch (Platform.operatingSystem) {
      'android' => 'Android',
      'ios' => 'iOS',
      'linux' => 'Linux',
      'macos' => 'macOS',
      'windows' => 'Windows',
      'fuchsia' => 'Fuchsia',
      _ => 'Unknown',
    };

/// Environment variable that overrides the application data directory, see [_resolveAppDataPath].
const String appDataDirEnvironmentVariable = 'MOMENTOBOOTH_DATA_DIR';

/// Files that are copied from the default data directory into an overridden one that does not have them yet, so a
/// new data directory starts from the current configuration instead of from scratch.
const List<String> _seededAppDataFileNames = ['Settings.toml', 'Projects.toml'];

Future<void> initializeEnvironmentInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  appDataPath = await _resolveAppDataPath();
  helperLibraryVersionInfo = await lib_init_api.getVersionInfo();

  getIt<Talker>().info({
    "OS": osFriendlyName,
    "App version": "${packageInfo.version} (build ${packageInfo.buildNumber})",
    "Flutter version": FlutterVersion.version!,
    "Helper library version": helperLibraryVersionInfo.libraryVersion,
    "Helper library Rust compiler version": helperLibraryVersionInfo.rustVersion,
    "Helper library Rust target": helperLibraryVersionInfo.rustTarget,
    "libgphoto2 version": helperLibraryVersionInfo.libgphoto2Version,
    "libusb version": helperLibraryVersionInfo.libusbVersion,
  });
}

/// Resolves the directory for settings and other application data.
///
/// The `--data-dir` argument takes precedence over the [appDataDirEnvironmentVariable] environment variable, which
/// takes precedence over the platform default. An override allows e.g. separate configurations per development
/// branch or worktree. Files from [_seededAppDataFileNames] missing in an overridden directory are copied from the
/// default directory.
Future<String> _resolveAppDataPath() async {
  String defaultPath = (await getApplicationSupportDirectory()).path;
  String? overridePath = getIt<ArgResults>().option('data-dir') ?? Platform.environment[appDataDirEnvironmentVariable];
  if (overridePath == null || overridePath.trim().isEmpty) return defaultPath;

  String resolvedOverridePath = path.normalize(path.absolute(overridePath.trim()));
  if (path.equals(resolvedOverridePath, defaultPath)) return defaultPath;

  await Directory(resolvedOverridePath).create(recursive: true);
  getIt<Talker>().info("Using application data directory override: $resolvedOverridePath");

  for (String fileName in _seededAppDataFileNames) {
    File source = File(path.join(defaultPath, fileName));
    File target = File(path.join(resolvedOverridePath, fileName));
    if (target.existsSync() || !source.existsSync()) continue;

    await source.copy(target.path);
    getIt<Talker>().info("Seeded $fileName from the default application data directory");
  }

  return resolvedOverridePath;
}

AppVersionInfo get appVersionInfo => _appVersionInfo ??= AppVersionInfo(
      appVersion: packageInfo.version,
      appBuild: int.parse(packageInfo.buildNumber),
      flutterVersion: FlutterVersion.version!,
      rustVersion: helperLibraryVersionInfo.rustVersion,
      rustTarget: helperLibraryVersionInfo.rustTarget,
    );

String get exifTagSoftwareName => '${packageInfo.appName} ${packageInfo.version} build ${packageInfo.buildNumber} ($osFriendlyName)';
