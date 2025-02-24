import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app.dart';
import 'package:momento_booth/extensions/get_it_extension.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/_all.dart';
import 'package:momento_booth/models/project_data.dart';
import 'package:momento_booth/repositories/_all.dart';
import 'package:momento_booth/src/rust/api/initialization.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/src/rust/models/logging.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker/talker.dart';

final GetIt getIt = GetIt.instance;

void main(List<String> arguments) async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  var parser = ArgParser()
  ..addFlag("fullscreen", abbr: 'f', help: 'Run in fullscreen mode', defaultsTo: false)
  ..addOption("open", abbr: 'o', help: 'Open a file or directory');
  final args = parser.parse(arguments);

  // This can be unawaited, as onboarding flow will keep user from entering core functionality while this is still ongoing.
  unawaited(_initializeApp(args));

  String sentryDsn = await _resolveSentryDsnOverride() ?? const String.fromEnvironment("SENTRY_DSN", defaultValue: '');
  await SentryFlutter.init(
    (options) {
      options
        ..tracesSampleRate = 1.0
        ..dsn = sentryDsn
        ..environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development')
        ..release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
    },
    appRunner: () => runApp(const App()),
  );
}

Future<String?> _resolveSentryDsnOverride() async {
  String executablePath = Platform.resolvedExecutable;
  String possibleSentryDsnOverridePath = path.join(path.dirname(executablePath), "sentry_dsn_override.txt");

  File sentryDsnOverrideFile = File(possibleSentryDsnOverridePath);
  if (!sentryDsnOverrideFile.existsSync()) return null;
  return (await sentryDsnOverrideFile.readAsString()).trim();
}

Future<void> _initializeApp(ArgResults args) async {
  getIt
    ..enableRegisteringMultipleInstancesOfOneType()

    // Log
    ..registerSingleton(Talker(settings: TalkerSettings()))
    ..registerSingleton(ObservableList<Subsystem>())

    // Repositories
    ..registerSingleton<SecretsRepository>(const SecureStorageSecretsRepository())

    // Managers
    ..registerManager(StatsManager())
    ..registerManager(ProjectManager())
    ..registerManager(SfxManager())
    ..registerManager(SettingsManager())
    ..registerManager(WindowManager())
    ..registerManager(LiveViewManager())
    ..registerManager(MqttManager())
    ..registerManager(NotificationsManager())
    ..registerManager(PrintingManager())
    ..registerManager(PhotosManager());

  await RustLib.init();
  _initializeLog();
  await initializeLibrary();

  await initializeEnvironmentInfo();

  getIt
    ..registerSingleton<SerialiableRepository<Settings>>(
      TomlSerializableRepository(path.join(appDataPath, "Settings.toml"), Settings.fromJson),
    )
    ..registerSingleton<SerialiableRepository<Stats>>(
      TomlSerializableRepository(path.join(appDataPath, "Stats.toml"), Stats.fromJson),
    )
    ..registerSingleton<SerialiableRepository<ProjectsList>>(
      TomlSerializableRepository(path.join(appDataPath, "Projects.toml"), ProjectsList.fromJson),
    );

  await getIt<SettingsManager>().initializeSafe();
  await _createPathsSafe();

  await getIt<StatsManager>().initializeSafe();
  await getIt<ProjectManager>().initializeSafe();
  // Open a project if a directory is given
  // TODO decide what to do if the folder does not exist yet.
  if (args.option("open") != null)  {
    await getIt<ProjectManager>().open(args.option("open")!);
  }
  await getIt<WindowManager>().initializeSafe();
  if (args.flag("fullscreen")) {
    getIt<WindowManager>().setFullscreen(true);
  }
  await getIt<LiveViewManager>().initializeSafe();
  await getIt<MqttManager>().initializeSafe();
  await getIt<SfxManager>().initializeSafe();
  await getIt<PrintingManager>().initializeSafe();
  getIt<NotificationsManager>().initialize();
}

void _initializeLog() {
  Talker talker = getIt<Talker>();
  initializeLog().listen((msg) {
    LogLevel logLevel = switch (msg.logLevel) {
      Level.error => LogLevel.error,
      Level.warn => LogLevel.warning,
      Level.info => LogLevel.info,
      Level.debug => LogLevel.debug,
      Level.trace => LogLevel.verbose,
    };
    talker.log("Lib: ${msg.lbl} - ${msg.msg}", logLevel: logLevel);
  });
}

Future<void> _createPathsSafe() async {
  List<String> paths = [
    getIt<SettingsManager>().settings.hardware.captureLocation,
  ];

  for (String path in paths) {
    createPathSafe(path);
  }
}
