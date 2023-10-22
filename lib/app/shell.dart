import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/app/photo_booth.dart';
import 'package:momento_booth/app/widgets/fps_monitor.dart';
import 'package:momento_booth/app/widgets/hotkey_monitor.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/custom_rect_tween.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';

part 'shell.routes.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with UiLoggy, WidgetsBindingObserver {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [
      HeroController(createRectTween: (begin, end) => CustomRectTween(begin: begin, end: end)),
    ],
    initialLocation: "/photo_booth",
  );

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FpsMonitor(
      child: HotkeyMonitor(
        router: _router,
        child: FluentApp(
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
        ),
      ),
    );
  }

  @override
  void dispose() {
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
