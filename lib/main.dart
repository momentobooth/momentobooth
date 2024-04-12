import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/app/shell/shell.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/utils/environment_variables.dart';
import 'package:momento_booth/utils/platform_and_app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await RustLib.init();
  _ensureGPhoto2EnvironmentVariables();

  WidgetsFlutterBinding.ensureInitialized();
  await initialize();

  Loggy.initLoggy(logPrinter: StreamPrinter(const PrettyDeveloperPrinter()));

  await HelperLibraryInitializationManager.instance.initialize();
  await SettingsManager.instance.load();
  await StatsManager.instance.load();
  await WindowManager.instance.initialize();
  LiveViewManager.instance.initialize();
  MqttManager.instance.initialize();
  await SfxManager.instance.initialize();
  NotificationsManager.instance.initialize();

  await SentryFlutter.init(
    (options) {
      options
        ..tracesSampleRate = 1.0
        ..dsn = const String.fromEnvironment("SENTRY_DSN", defaultValue: "")
        ..environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development')
        ..release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
    },
    appRunner: () => runApp(const Shell()),
  );
}

void _ensureGPhoto2EnvironmentVariables() {
  if (!Platform.isWindows) return;

  // Read from Dart defines
  const String iolibsDefine = String.fromEnvironment("IOLIBS");
  const String camlibsDefine = String.fromEnvironment("CAMLIBS");
  if (iolibsDefine.isEmpty || camlibsDefine.isEmpty) return;

  // Set to current process using msvcrt API
  // See: https://stackoverflow.com/questions/4788398/changes-via-setenvironmentvariable-do-not-take-effect-in-library-that-uses-geten
  putenv_s("IOLIBS", iolibsDefine);
  putenv_s("CAMLIBS", camlibsDefine);
}
