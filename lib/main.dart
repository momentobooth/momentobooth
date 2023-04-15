import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/extensions/build_context_extension.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_bridge.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/fade_transition_page.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/live_view_background.dart';
import 'package:flutter_rust_bridge_example/views/multi_capture_screen/multi_capture_screen.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'main.routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hotkeys
  await hotKeyManager.unregisterAll();

  // Settings
  await SettingsManagerBase.instance.load();

  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
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

class _AppState extends State<App> {

  final GoRouter _router = GoRouter(routes: rootRoutes);

  bool _settingsOpen = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    _initHotKeys();
    super.initState();
  }

  void _toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    print("Setting fullscreen to $_isFullScreen");
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
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      color: context.theme.primaryColor,
      localizationsDelegates: [
        FluentLocalizations.delegate,
      ],
      builder: (context, child) {
        // This stack allows us to put the Settings screen on top
        return LiveViewBackground(
          child: Stack(
            children: [
              child!,
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
