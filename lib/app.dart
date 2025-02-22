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
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/full_screen_dialog.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/photo_booth.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:window_manager/window_manager.dart' show WindowListener, windowManager;

part 'app.routes.dart';
part 'app.hotkeys.dart';

class App extends StatefulWidget {

  const App({super.key});

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> with WindowListener {

  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [HeroController()],
    initialLocation: '/onboarding',
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
