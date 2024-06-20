import 'package:momento_booth/models/app_version_info.dart';
import 'package:momento_booth/src/rust/models/version_info.dart';
import 'package:momento_booth/utils/system/platform_helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';

late final PackageInfo packageInfo;
late final VersionInfo rustVersionInfo;
late final String flutterVersion;

String get exifTagSoftwareName => '${packageInfo.appName} ${packageInfo.version} build ${packageInfo.buildNumber} ($osFriendlyName)';

AppVersionInfo? _appVersionInfo;

AppVersionInfo get appVersionInfo => _appVersionInfo ??= AppVersionInfo(
  appVersion: packageInfo.version,
  appBuild: int.parse(packageInfo.buildNumber),
  flutterVersion: const String.fromEnvironment("FLUTTER_VERSION", defaultValue: 'Unknown'),
  rustVersion: rustVersionInfo.rustVersion,
  rustTarget: rustVersionInfo.rustTarget,
);

Future<void> initializeAppVersionHelpers(VersionInfo libraryVersionInfo) async {
  packageInfo = await PackageInfo.fromPlatform();
  rustVersionInfo = libraryVersionInfo;
}
