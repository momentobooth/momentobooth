import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:args/args.dart';
import 'package:ffi/ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:momento_booth/managers/app_init_manager.dart';
import 'package:momento_booth/momento_booth_app.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:win32/win32.dart';

final GetIt getIt = GetIt.instance;

void main(List<String> arguments) async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  var parser = ArgParser()
    ..addFlag('fullscreen', abbr: 'f', help: 'Run in fullscreen mode', defaultsTo: false)
    ..addOption('wait-for-pid', abbr: 'w', help: 'Wait for a previous instance to be closed before starting')
    ..addOption('open', abbr: 'o', help: 'Open given directory as a project');
  getIt
    ..registerSingleton(parser.parse(arguments))
    ..registerSingleton(AppInitManager());

  String? previousInstance = getIt<ArgResults>().option('wait-for-pid');
  if (previousInstance != null) await _waitForPreviousInstance(int.parse(previousInstance));

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

Future<void> _waitForPreviousInstance(int pid) async {
  await using((arena) async {
    final hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (hProcess == NULL) return;

    final lpExitCode = arena<Uint32>();
    bool isProcessActive = true;
    while (isProcessActive) {
      if (GetExitCodeProcess(hProcess, lpExitCode) == 0) {
        // Failure to get process exit information. We assume it's exited to not get the application stuck on waiting.
        isProcessActive = false;
      } else {
        isProcessActive = lpExitCode.value == STILL_ACTIVE;
      }

      if (isProcessActive) await Future.delayed(const Duration(seconds: 1));
    }

    CloseHandle(hProcess);
  });
}
