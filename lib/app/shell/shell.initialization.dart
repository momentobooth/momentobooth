part of 'shell.dart';

Future<void> _initializeApp() async {
  getIt
    ..enableRegisteringMultipleInstancesOfOneType()

    // Log
    ..registerSingleton(Talker(settings: TalkerSettings()))
    ..registerSingleton(ObservableList<Subsystem>());

  await RustLib.init();
  _initializeLog();
  await initializeLibrary();

  getIt
    // Repositories
    ..registerSingleton<SecretsRepository>(const SecureStorageSecretsRepository())
    ..registerSingleton<SerialiableRepository<Settings>>(
      TomlSerializableRepository(path.join(documentsPath, "MomentoBooth_Settings.toml"), Settings.fromJson),
    )
    ..registerSingleton<SerialiableRepository<Stats>>(
      TomlSerializableRepository(path.join(documentsPath, "MomentoBoothstats.toml"), Stats.fromJson),
    )

    // Managers
    ..registerManager(StatsManager())
    ..registerManager(SfxManager())
    ..registerManager(SettingsManager())
    ..registerManager(WindowManager())
    ..registerManager(LiveViewManager())
    ..registerManager(MqttManager())
    ..registerManager(NotificationsManager())
    ..registerManager(PrintingManager());

  await _createPathsSafe();

  await getIt<SettingsManager>().initialize();
  await getIt<StatsManager>().initialize();
  await getIt<WindowManager>().initialize();
  getIt<LiveViewManager>().initialize();
  getIt<MqttManager>().initialize();
  await getIt<SfxManager>().initialize();
  getIt<NotificationsManager>().initialize();
  getIt<PrintingManager>().initialize();
}

void _initializeLog() {
  Talker talker = getIt<Talker>();
  setupLogStream().listen((msg) {
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
    getIt<SettingsManager>().settings.templatesFolder,
    getIt<SettingsManager>().settings.output.localFolder,
    getIt<SettingsManager>().settings.hardware.captureLocation,
    getIt<SettingsManager>().settings.hardware.captureStorageLocation,
  ];

  for (String path in paths) {
    createPathSafe(path);
  }
}
