import 'dart:io';

import 'package:momento_booth/src/rust/models/version_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

late final PackageInfo packageInfo;
late final String documentsPath;
late final VersionInfo rustVersionInfo;

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

Future<void> initializeEnvironmentInfo(VersionInfo libraryVersionInfo) async {
  packageInfo = await PackageInfo.fromPlatform();
  documentsPath = (await getApplicationDocumentsDirectory()).toString();
  rustVersionInfo = libraryVersionInfo;
}
