import 'dart:io';

import 'package:path_provider/path_provider.dart';

late final String documentsPath;

String get osFriendlyName => switch (Platform.operatingSystem) {
  'android' => 'Android',
  'ios' => 'iOS',
  'linux' => 'Linux',
  'macos' => 'macOS',
  'windows' => 'Windows',
  'fuchsia' => 'Fuchsia',
  _ => 'Unknown',
};

Future<void> initializePlatformHelpers() async {
  documentsPath = (await getApplicationDocumentsDirectory()).toString();
}
