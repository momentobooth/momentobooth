import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/theme/momento_booth_theme.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/fade_transition_page.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view_background.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen.dart';
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
  static const updateLastAliveTimeout = Duration(milliseconds: 100);
  late Timer _returnHomeTimer, _updateLastAliveTimeTimer;

  @override
  void initState() {
    _initHotKeys();
    // Check if the window is fullscreen from the start.
    windowManager.isFullScreen().then((value) => _isFullScreen = value);
    _returnHomeTimer = Timer(returnHomeTimeout, _returnHome);
    _updateLastAliveTimeTimer = Timer.periodic(updateLastAliveTimeout, _updateLastAliveTime);
    _router.addListener(() { onActivity(null); });
    super.initState();
  }

  void _toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    loggy.debug("Setting fullscreen to $_isFullScreen");
    windowManager.setFullScreen(_isFullScreen);
  }

  void _initHotKeys() {
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

  void _updateLastAliveTime(Timer timer) {
    rustLibraryApi.updateFlutterAppLastAliveTime();
  }

  /// Method that is fired when a user does any kind of touch or the route changes.
  /// This resets the return home timer.
  void onActivity(PointerEvent? event) {
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
    return WidgetsApp.router(
      routerConfig: _router,
      color: context.theme.primaryColor,
      localizationsDelegates: [
        FluentLocalizations.delegate,
      ],
      builder: (context, child) {
        // This stack allows us to put the Settings screen on top
        return LiveViewBackground(
          child: Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: onActivity,
                child: child!,
              ),
              _settingsOpen ? _settingsScreen : const SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Widget get _settingsScreen {
    return FluentApp(
      home: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        margin: EdgeInsets.all(32),
        clipBehavior: Clip.hardEdge,
        child: SettingsScreen(),
      ),
    );
  }

}
