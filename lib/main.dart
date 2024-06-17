import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:momento_booth/app/shell/shell.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

Future<String?> _resolveSentryDsnOverride() async {
  String executablePath = Platform.resolvedExecutable;
  String possibleSentryDsnOverridePath = path.join(path.dirname(executablePath), "sentry_dsn_override.txt");

  File sentryDsnOverrideFile = File(possibleSentryDsnOverridePath);
  if (!sentryDsnOverrideFile.existsSync()) return null;
  return (await sentryDsnOverrideFile.readAsString()).trim();
}
