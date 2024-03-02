import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/app/photo_booth/photo_booth.dart';
import 'package:momento_booth/app/shell/widgets/fps_monitor.dart';
import 'package:momento_booth/app/shell/widgets/shell_hotkey_monitor.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/custom_rect_tween.dart';
import 'package:momento_booth/views/base/full_screen_dialog.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:window_manager/window_manager.dart';

part 'shell.routes.dart';

class Shell extends StatefulWidget {

  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();

}

class _ShellState extends State<Shell> with UiLoggy, WindowListener {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [
      HeroController(createRectTween: (begin, end) => CustomRectTween(begin: begin, end: end)),
    ],
    initialLocation: '/photo_booth',
  );

  @override
  void initState() {
    super.initState();

    // This uses the window_manager package to listen for window close events,
    // instead of WidgetsBindingObserver as it seems more reliable.
    windowManager
      ..addListener(this)
      ..setPreventClose(true);
  }

  @override
  Widget build(BuildContext context) {
    return FpsMonitor(
      child: ShellHotkeyMonitor(
        router: _router,
        child: Observer(
          builder: (context) => FluentApp.router(
            routerConfig: _router,
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
          ),
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
    await LiveViewManager.instance.gPhoto2Camera?.dispose();
    await windowManager.destroy();
  }

}
