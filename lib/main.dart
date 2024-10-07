import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:momento_booth/app/shell/shell.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/repositories/secret/secret_repository.dart';
import 'package:momento_booth/repositories/secret/secure_storage_secret_repository.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  await RustLib.init();

  WidgetsFlutterBinding.ensureInitialized();

  getIt
    ..registerSingleton(Talker(
      settings: TalkerSettings(),
    ))
    ..registerSingleton<SecretRepository>(const SecureStorageSecretRepository());

  await initializeEnvironmentInfo();
  await HelperLibraryInitializationManager.instance.initialize();
  await SettingsManager.instance.load();
  await StatsManager.instance.load();
  await WindowManager.instance.initialize();
  LiveViewManager.instance.initialize();
  MqttManager.instance.initialize();
  await SfxManager.instance.initialize();
  NotificationsManager.instance.initialize();
  PrintingManager.instance.initialize();

  await _createPathsSafe();

  String sentryDsn = await _resolveSentryDsnOverride() ?? const String.fromEnvironment("SENTRY_DSN", defaultValue: '');
  await SentryFlutter.init(
    (options) {
      options
        ..tracesSampleRate = 1.0
        ..dsn = sentryDsn
        ..environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development')
        ..release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
    },
    appRunner: () => runApp(const Shell()),
  );
}

Future<void> _createPathsSafe() async {
  List<String> paths = [
    SettingsManager.instance.settings.templatesFolder,
    SettingsManager.instance.settings.output.localFolder,
    SettingsManager.instance.settings.hardware.captureLocation,
    SettingsManager.instance.settings.hardware.captureStorageLocation,
  ];

  for (String path in paths) {
    createPathSafe(path);
  }
}

Future<String?> _resolveSentryDsnOverride() async {
  String executablePath = Platform.resolvedExecutable;
  String possibleSentryDsnOverridePath = path.join(path.dirname(executablePath), "sentry_dsn_override.txt");

  File sentryDsnOverrideFile = File(possibleSentryDsnOverridePath);
  if (!sentryDsnOverrideFile.existsSync()) return null;
  return (await sentryDsnOverrideFile.readAsString()).trim();
}
