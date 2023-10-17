import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/managers/helper_library_initialization_manager.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/managers/notifications_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/sfx_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/shell/widgets/activity_monitor.dart';
import 'package:momento_booth/shell/widgets/fps_monitor.dart';
import 'package:momento_booth/shell/widgets/hotkey_monitor.dart';
import 'package:momento_booth/theme/momento_booth_theme.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/utils/custom_rect_tween.dart';
import 'package:momento_booth/utils/environment_variables.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view_background.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:momento_booth/views/share_screen/share_screen.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'main.routes.dart';

late PackageInfo packageInfo;

void main() async {
  _ensureGPhoto2EnvironmentVariables();

  WidgetsFlutterBinding.ensureInitialized();

  // App info
  packageInfo = await PackageInfo.fromPlatform();

  // Logging
  Loggy.initLoggy(logPrinter: StreamPrinter(const PrettyDeveloperPrinter()));

  // Helper library initialization
  HelperLibraryInitializationManager.instance.initialize();

  // Settings
  await SettingsManager.instance.load();

  // Stats
  await StatsManager.instance.load();

  // Windows manager (used for full screen)
  await WindowManager.instance.initialize();

  // Live view manager init
  LiveViewManager.instance.initialize();

  // MQTT client manager init
  MqttManager.instance.initialize();

  // Sfx manager init
  await SfxManager.instance.initialize();

  await SentryFlutter.init(
    (options) {
      options
        ..tracesSampleRate = 1.0
        ..dsn = const String.fromEnvironment("SENTRY_DSN", defaultValue: "")
        ..environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development')
        ..release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
    },
    appRunner: () => runApp(const App()),
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

class App extends StatefulWidget {

  const App({super.key});

  @override
  State<App> createState() => AppState();

}

class AppState extends State<App> with UiLoggy, WidgetsBindingObserver {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [
      GoRouterObserver(),
      HeroController(createRectTween: (begin, end) => CustomRectTween(begin: begin, end: end)),
    ],
    initialLocation: StartScreen.defaultRoute,
  );

  bool settingsOpen = false;

  static const statusCheckPeriod = Duration(seconds: 5);
  late Timer _statusCheckTimer;

  @override
  void initState() {
    _statusCheckTimer = Timer.periodic(statusCheckPeriod, (_) => _statusCheck());
    
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  Future<void> _statusCheck() async {
    final printerNames = SettingsManager.instance.settings.hardware.printerNames;
    final printersStatus = await compute(checkPrintersStatus, printerNames);
    NotificationsManager.instance.notifications.clear();
    printersStatus.forEachIndexed((index, element) {
      final hasErrorNotification = InfoBar(title: const Text("Printer error"), content: Text("Printer ${index+1} has an error."), severity: InfoBarSeverity.warning);
      final paperOutNotification = InfoBar(title: const Text("Printer out of paper"), content: Text("Printer ${index+1} is out of paper."), severity: InfoBarSeverity.warning);
      final longQueueNotification = InfoBar(title: const Text("Long printing queue"), content: Text("Printer ${index+1} has a long queue (${element.jobs} jobs). It might take a while for your print to appear."), severity: InfoBarSeverity.info);
      if (element.jobs >= SettingsManager.instance.settings.hardware.printerQueueWarningThreshold) {
        NotificationsManager.instance.notifications.add(longQueueNotification);
      }
      if (element.hasError) {
        NotificationsManager.instance.notifications.add(hasErrorNotification);
      }
      if (element.paperOut) {
        NotificationsManager.instance.notifications.add(paperOutNotification);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FpsMonitor(
      child: ActivityMonitor(
        router: _router,
        child: HotkeyMonitor(
          router: _router,
          child: MomentoBoothTheme(
            data: MomentoBoothThemeData.defaults(),
            child: Builder(
              builder: _getWidgetsApp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getWidgetsApp(BuildContext context) {
    return FluentTheme(
      data: FluentThemeData(),
      child: WidgetsApp.router(
        routerConfig: _router,
        color: context.theme.primaryColor,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FluentLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('nl'), // Dutch
        ],
        locale: SettingsManager.instance.settings.ui.language.toLocale(),
        builder: (context, child) {
          return LiveViewBackground(
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  child!,
                  Visibility(
                    visible: settingsOpen,
                    maintainState: true,
                    child: _settingsScreen,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get _settingsScreen {
    return FluentApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FluentLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('nl'), // Dutch
      ],
      locale: SettingsManager.instance.settings.ui.language.toLocale(),
      home: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        margin: const EdgeInsets.all(32),
        clipBehavior: Clip.hardEdge,
        child: const SettingsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer.cancel();
    _router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await LiveViewManager.instance.gPhoto2Camera?.dispose();
    return super.didRequestAppExit();
  }

}
