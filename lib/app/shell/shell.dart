import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app/photo_booth/photo_booth.dart';
import 'package:momento_booth/app/shell/onboarding_page.dart';
import 'package:momento_booth/app/shell/widgets/shell_hotkey_monitor.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/get_it_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/repositories/secret/secret_repository.dart';
import 'package:momento_booth/repositories/secret/secure_storage_secret_repository.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/views/base/full_screen_dialog.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:window_manager/window_manager.dart' show WindowListener, windowManager;

part 'shell.routes.dart';

class Shell extends StatefulWidget {

  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();

}

class _ShellState extends State<Shell> with WindowListener {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [HeroController()],
    initialLocation: '/onboarding',
  );

  @override
  void initState() {
    super.initState();

    _initializeApp();

    // This uses the window_manager package to listen for window close events,
    // instead of WidgetsBindingObserver as it seems more reliable.
    windowManager
      ..addListener(this)
      ..setPreventClose(true);
  }

  @override
  Widget build(BuildContext context) {
    return ShellHotkeyMonitor(
      router: _router,
      child: Observer(
        builder: (context) => FluentApp.router(
          scrollBehavior: ScrollConfiguration.of(context),
          routerConfig: _router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FluentLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
          ],
          locale: const Locale('en'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    await getIt<LiveViewManager>().gPhoto2Camera?.dispose();
    await windowManager.destroy();
  }

}

Future<void> _initializeApp() async {
  await RustLib.init();

  getIt
    ..enableRegisteringMultipleInstancesOfOneType()

    // Log
    ..registerSingleton(Talker(
      settings: TalkerSettings(),
    ));

  await initializeEnvironmentInfo();

  getIt
    // Repositories
    ..registerSingleton<SecretRepository>(const SecureStorageSecretRepository())

    // Managers
    ..registerManager(HelperLibraryInitializationManager())
    ..registerManager(StatsManager())
    ..registerManager(SfxManager())
    ..registerManager(SettingsManager())
    ..registerManager(WindowManager())
    ..registerManager(LiveViewManager())
    ..registerManager(MqttManager())
    ..registerManager(NotificationsManager())
    ..registerManager(PrintingManager());

  await getIt<SettingsManager>().load();
  await getIt<StatsManager>().load();
  await getIt<WindowManager>().initialize();
  getIt<LiveViewManager>().initialize();
  getIt<MqttManager>().initialize();
  await getIt<SfxManager>().initialize();
  getIt<NotificationsManager>().initialize();
  getIt<PrintingManager>().initialize();

  await _createPathsSafe();
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
