import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/theme/momento_booth_theme.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/fade_transition_page.dart';
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
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'main.routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logging
  Loggy.initLoggy(logPrinter: StreamPrinter(const PrettyDeveloperPrinter()));

  // Hotkeys
  await hotKeyManager.unregisterAll();

  // Settings
  await SettingsManagerBase.instance.load();

  // Stats
  await StatsManagerBase.instance.load();

  // Windows manager (used for full screen)
  await windowManager.ensureInitialized();

  // Native library init
  init();

  runApp(const App());
}

class App extends StatefulWidget {

  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> with UiLoggy {

  final GoRouter _router = GoRouter(routes: rootRoutes, observers: [GoRouterObserver()]);

  bool _settingsOpen = false;
  bool _isFullScreen = false;

  static const returnHomeTimeout = Duration(seconds: 45);
  late Timer _returnHomeTimer;
  static const statusCheckPeriod = Duration(seconds: 5);
  late Timer _statusCheckTimer;

  @override
  void initState() {
    _initHotKeys();
    // Check if the window is fullscreen from the start.
    windowManager.isFullScreen().then((value) => _isFullScreen = value);
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
    _statusCheckTimer = Timer.periodic(statusCheckPeriod, (_) => _statusCheck());
    _router.addListener(() => onActivity(isTap: false));
    super.initState();
  }

  void _statusCheck() async {
    bool hasError, paperOut;
    final printerNames = SettingsManagerBase.instance.settings.hardware.printerNames;
    (hasError, paperOut) = await compute(checkPrinterStatus, printerNames);
    loggy.debug("Status check $hasError, $paperOut");
  }

  void _toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    loggy.debug("Setting fullscreen to $_isFullScreen");
    windowManager.setFullScreen(_isFullScreen);
  }

  void _initHotKeys() {
    // Ctrl + S opens/closes settings
    hotKeyManager.register(
      HotKey(
        KeyCode.keyS,
        modifiers: [KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) {
        setState(() => _settingsOpen = !_settingsOpen);
        loggy.debug("Settings ${_settingsOpen ? "opened" : "closed"}");
      },
    );
    // Ctrl + M opens manual collage maker screen
    hotKeyManager.register(
      HotKey(
        KeyCode.keyM,
        modifiers: [KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) {
        if (_router.location == ManualCollageScreen.defaultRoute) {
          _router.go(StartScreen.defaultRoute);
        } else {
          _router.go(ManualCollageScreen.defaultRoute);
        }
      },
    );
    // Alt + enter toggles full-screen
    hotKeyManager.register(
      HotKey(
        KeyCode.enter,
        modifiers: [KeyModifier.alt],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) {
        setState(_toggleFullscreen);
      },
    );
    // Ctrl + F toggles full-screen
    hotKeyManager.register(
      HotKey(
        KeyCode.keyF,
        modifiers: [KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) {
        setState(_toggleFullscreen);
      },
    );
  }

  void _returnHome() {
    loggy.debug("No activity in $returnHomeTimeout, returning to homescreen");
    _router.go(StartScreen.defaultRoute);
  }

  /// Method that is fired when a user does any kind of touch or the route changes.
  /// This resets the return home timer.
  void onActivity({bool isTap = false}) {
    if (isTap) { StatsManagerBase.instance.addTap(); }
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
          FluentLocalizations.delegate,
        ],
        builder: (context, child) {
          // This stack allows us to put the Settings screen on top
          return LiveViewBackground(
            child: Center(
              child: Stack(
                children: [
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) => onActivity(isTap: true),
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
    return FluentApp(
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

}
