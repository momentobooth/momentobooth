import 'dart:io';

import 'package:momento_booth/main.dart';
import 'package:momento_booth/src/rust/api/initialization.dart' as lib_init_api;
import 'package:momento_booth/src/rust/models/version_info.dart' as lib_version_info_models;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

late final PackageInfo packageInfo;
late final String documentsPath;
late final lib_version_info_models.VersionInfo helperLibraryVersionInfo;
const String flutterVersion = String.fromEnvironment("FLUTTER_VERSION");

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

Future<void> initializeEnvironmentInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
  documentsPath = (await getApplicationDocumentsDirectory()).toString();
  helperLibraryVersionInfo = await lib_init_api.getVersionInfo();

  getIt<Talker>().info({
    "OS": osFriendlyName,
    "App version": "${packageInfo.version} (build ${packageInfo.buildNumber})",
    "Flutter version": flutterVersion,
    "Helper library version": helperLibraryVersionInfo.libraryVersion,
    "Helper library Rust compiler version": helperLibraryVersionInfo.rustVersion,
    "Helper library Rust target": helperLibraryVersionInfo.rustTarget,
    "libgphoto2 version": helperLibraryVersionInfo.libgphoto2Version,
    "libgexiv2 version": helperLibraryVersionInfo.libgexiv2Version,
  });
}
