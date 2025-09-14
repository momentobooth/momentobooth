import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:momento_booth/managers/app_init_manager.dart';
import 'package:momento_booth/momento_booth_app.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';

final GetIt getIt = GetIt.instance;

void main(List<String> arguments) async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  var parser = ArgParser()
    ..addFlag("fullscreen", abbr: 'f', help: 'Run in fullscreen mode', defaultsTo: false)
    ..addOption("open", abbr: 'o', help: 'Open given directory as a project');
  getIt
    ..registerSingleton(parser.parse(arguments))
    ..registerSingleton(AppInitManager());
  unawaited(getIt<AppInitManager>().initializeApp());

  String sentryDsn = await _resolveSentryDsnOverride() ?? const String.fromEnvironment("SENTRY_DSN", defaultValue: '');
  await SentryFlutter.init(
    (options) {
      options
        ..tracesSampleRate = 1.0
        ..dsn = sentryDsn
        ..environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development')
        ..release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
    },
    appRunner: () => runApp(const MomentoBoothApp()),
  );
}

Future<String?> _resolveSentryDsnOverride() async {
  String executablePath = Platform.resolvedExecutable;
  String possibleSentryDsnOverridePath = path.join(path.dirname(executablePath), "sentry_dsn_override.txt");

  File sentryDsnOverrideFile = File(possibleSentryDsnOverridePath);
  if (!sentryDsnOverrideFile.existsSync()) return null;
  return (await sentryDsnOverrideFile.readAsString()).trim();
}
