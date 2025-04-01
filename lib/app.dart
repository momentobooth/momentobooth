import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart' as onboarding;
import 'package:momento_booth/views/photo_booth_screen/photo_booth_shell.dart' as photo_booth;
import 'package:momento_booth/views/settings_screen/settings_screen.dart' as settings;

import 'package:window_manager/window_manager.dart' show WindowListener, windowManager;

part 'app.hotkeys.dart';

class App extends StatefulWidget {

  const App({super.key});

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> with WindowListener {

  final GoRouter _router = GoRouter(
    routes: [...onboarding.$appRoutes, ...photo_booth.$appRoutes, ...settings.$appRoutes],
    observers: [HeroController()],
    initialLocation: const onboarding.OnboardingRoute().location,
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
    return _HotkeyResponder(
      router: _router,
      child: Observer(
        builder: (context) {
          return FluentApp.router(
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
              Locale('nl'), // Dutch
            ],
            locale: getIt<SettingsManager>().settings.ui.language.toLocale(),
          );
        }
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
