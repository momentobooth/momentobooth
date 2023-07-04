import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/notifications_manager.dart';
import 'package:momento_booth/managers/hotkey_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/models/hotkey_action.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/theme/momento_booth_theme.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/utils/custom_rect_tween.dart';
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
import 'package:momento_booth/views/share_screen/share_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:win32/win32.dart';

part 'main.routes.dart';

void main() async {
  _ensureGPhoto2EnvironmentVariables();

  WidgetsFlutterBinding.ensureInitialized();

  // Logging
  Loggy.initLoggy(logPrinter: StreamPrinter(const PrettyDeveloperPrinter()));

  // Hotkeys
  await HotkeyManager.instance.initialize();

  // Settings
  await SettingsManager.instance.load();

  // Stats
  await StatsManager.instance.load();

  // Windows manager (used for full screen)
  await WindowManager.instance.initialize();

  // Native library init
  await init();

  await SentryFlutter.init(
    (options) {
      options.tracesSampleRate = 1.0;
      options.dsn = const String.fromEnvironment("SENTRY_DSN", defaultValue: "");
      options.environment = const String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'Development');
      options.release = const String.fromEnvironment("SENTRY_RELEASE", defaultValue: 'Development');
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

  // Set to current process using win32 API
  using((arena) {
    SetEnvironmentVariable("IOLIBS".toNativeUtf16(allocator: arena), iolibsDefine.toNativeUtf16(allocator: arena));
    SetEnvironmentVariable("CAMLIBS".toNativeUtf16(allocator: arena), camlibsDefine.toNativeUtf16(allocator: arena));
  });
}

class App extends StatefulWidget {

  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> with UiLoggy, WidgetsBindingObserver {

  final GoRouter _router = GoRouter(
    routes: rootRoutes,
    observers: [
      GoRouterObserver(),
      HeroController(createRectTween: (begin, end) => CustomRectTween(begin: begin!, end: end!)),
    ],
    initialLocation: StartScreen.defaultRoute,
  );

  bool _settingsOpen = false;

  static const returnHomeTimeout = Duration(seconds: 45);
  late Timer _returnHomeTimer;
  static const statusCheckPeriod = Duration(seconds: 5);
  late Timer _statusCheckTimer;

  Stream<HotkeyAction> get _hotkeyActionStream => HotkeyManager.instance.hotkeyActionStream;
  late StreamSubscription<HotkeyAction> _hotkeyActionStreamSubscription;

  @override
  void initState() {
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
    _statusCheckTimer = Timer.periodic(statusCheckPeriod, (_) => _statusCheck());
    _router.routerDelegate.addListener(() => _onActivity(isTap: false));
    _hotkeyActionStreamSubscription = _hotkeyActionStream.listen(_runHotkeyAction);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _statusCheck() async {
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
    if (GoRouterState.of(context).location == StartScreen.defaultRoute) return;
    loggy.debug("No activity in $returnHomeTimeout, returning to homescreen");
    _router.go(StartScreen.defaultRoute);
  }

  /// Method that is fired when a user does any kind of touch or the route changes.
  /// This resets the return home timer.
  void _onActivity({bool isTap = false}) {
    if (isTap) StatsManager.instance.addTap();
    _returnHomeTimer.cancel();
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
  }

  @override
  Widget build(BuildContext context) {
    return MomentoBoothTheme(
      data: MomentoBoothThemeData.defaults(),
      child: Builder(
        builder: (BuildContext context) {
          return _getWidgetsApp(context);
        },
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
          return LiveViewBackground(
            child: Center(
              child: Stack(
                children: [
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) => _onActivity(isTap: true),
                    child: child!,
                  ),
                  _settingsOpen ? _settingsScreen : const SizedBox(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get _settingsScreen {
    return Container(
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
    );
  }

  @override
  void dispose() {
    _returnHomeTimer.cancel();
    _statusCheckTimer.cancel();
    _hotkeyActionStreamSubscription.cancel();
    _router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _runHotkeyAction(HotkeyAction event) {
    switch (event) {
      case HotkeyAction.openSettingsScreen:
        setState(() => _settingsOpen = !_settingsOpen);
        loggy.debug("Settings ${_settingsOpen ? "opened" : "closed"}");
      case HotkeyAction.openManualCollageScreen:
        if (GoRouterState.of(context).location == ManualCollageScreen.defaultRoute) {
          _router.go(StartScreen.defaultRoute);
        } else {
          _router.go(ManualCollageScreen.defaultRoute);
        }
      case HotkeyAction.goToHomeScreen:
        _router.go(StartScreen.defaultRoute);
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await LiveViewManager.instance.gPhoto2Camera?.dispose();
    return super.didRequestAppExit();
  }

}
