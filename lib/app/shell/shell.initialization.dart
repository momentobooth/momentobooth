part of 'shell.dart';

Future<void> _initializeApp() async {
  getIt
    ..enableRegisteringMultipleInstancesOfOneType()

    // Log
    ..registerSingleton(Talker(settings: TalkerSettings()))
    ..registerSingleton(ObservableList<Subsystem>());

  // TODO: handle errors
  await RustLib.init();
  _initializeLoggingFromRust();
  VersionInfo libraryVersionInfo = await initializeLibrary();
  await initializeEnvironmentInfo(libraryVersionInfo);

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

  await getIt<SettingsManager>().initialize();
  await getIt<StatsManager>().initialize();
  await getIt<WindowManager>().initialize();
  getIt<LiveViewManager>().initialize();
  getIt<MqttManager>().initialize();
  await getIt<SfxManager>().initialize();
  getIt<NotificationsManager>().initialize();
  getIt<PrintingManager>().initialize();
}

void _initializeLoggingFromRust() {
  Talker logger = getIt<Talker>();
  initializeLogging().listen((event) => switch (event.level) {
        LogLevel.debug => logger.debug("Lib: ${event.message}"),
        LogLevel.info => logger.info("Lib: ${event.message}"),
        LogLevel.warning => logger.warning("Lib: ${event.message}"),
        LogLevel.error => logger.error("Lib: ${event.message}"),
      });
}
