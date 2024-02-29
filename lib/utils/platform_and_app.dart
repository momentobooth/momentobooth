import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

late final PackageInfo packageInfo;

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

Future<void> initialize() async {
  packageInfo = await PackageInfo.fromPlatform();
}
