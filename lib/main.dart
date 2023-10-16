import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lemberfpsmonitor/lemberfpsmonitor.dart';
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
  State<App> createState() => _AppState();

}

class _AppState extends State<App> with UiLoggy, WidgetsBindingObserver {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [
      GoRouterObserver(),
      HeroController(createRectTween: (begin, end) => CustomRectTween(begin: begin, end: end)),
    ],
    initialLocation: StartScreen.defaultRoute,
  );

  bool _settingsOpen = false;

  static const returnHomeTimeout = Duration(seconds: 45);
  late Timer _returnHomeTimer;
  static const statusCheckPeriod = Duration(seconds: 5);
  late Timer _statusCheckTimer;

  @override
  void initState() {
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
    _statusCheckTimer = Timer.periodic(statusCheckPeriod, (_) => _statusCheck());
    _router.routerDelegate.addListener(() => _onActivity(isTap: false));
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

  void _returnHome() {
    if (_currentRouterLocation == StartScreen.defaultRoute) return;
    loggy.debug("No activity in $returnHomeTimeout, returning to homescreen");
    _router.go(StartScreen.defaultRoute);
  }

  /// Method that is fired when a user does any kind of touch or the route changes.
  /// This resets the return home timer.
  void _onActivity({bool isTap = false}) {
    if (isTap) {
      StatsManager.instance.addTap();
      SfxManager.instance.playClickSound();
    }
    _returnHomeTimer.cancel();
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
  }

  @override
  Widget build(BuildContext context) {
    return MomentoBoothTheme(
      data: MomentoBoothThemeData.defaults(),
      child: Builder(
        builder: _getWidgetsApp,
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
          // This stack allows us to put the Settings screen on top
          bool control = !Platform.isMacOS, meta = Platform.isMacOS;
          return CallbackShortcuts(
            bindings: {
              SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): () => _router.go(StartScreen.defaultRoute),
              SingleActivator(LogicalKeyboardKey.keyR, control: control, meta: meta): LiveViewManager.instance.restoreLiveView,
              SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): () {
                setState(() => _settingsOpen = !_settingsOpen);
                loggy.debug("Settings ${_settingsOpen ? "opened" : "closed"}"); 
              },
              SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): _toggleManualCollageScreen,
              SingleActivator(LogicalKeyboardKey.keyF, control: control, meta: meta): WindowManager.instance.toggleFullscreen,
              const SingleActivator(LogicalKeyboardKey.enter, alt: true): WindowManager.instance.toggleFullscreen,
            },
            child: LiveViewBackground(
              child: Center(
                child: Stack(
                  children: [
                    Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (_) => _onActivity(isTap: true),
                      child: child,
                    ),
                    Visibility(
                      visible: _settingsOpen,
                      maintainState: true,
                      child: _settingsScreen,
                    ),
                    Observer(
                      builder: (_) {
                        if (SettingsManager.instance.settings.debug.showFpsCounter) {
                          return FPSMonitor(
                            showFPSChart: true,
                            align: Alignment.topRight,
                            onFPSChanged: (fps) {},
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
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
    _returnHomeTimer.cancel();
    _statusCheckTimer.cancel();
    _router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _currentRouterLocation {
    final RouteMatch lastMatch = _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  void _toggleManualCollageScreen() {
    if (_currentRouterLocation == ManualCollageScreen.defaultRoute) {
      _router.go(StartScreen.defaultRoute);
    } else {
      _router.go(ManualCollageScreen.defaultRoute);
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await LiveViewManager.instance.gPhoto2Camera?.dispose();
    return super.didRequestAppExit();
  }

}
