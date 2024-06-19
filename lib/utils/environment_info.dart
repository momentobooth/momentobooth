import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

late final PackageInfo packageInfo;
late final String documentsPath;

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
}
