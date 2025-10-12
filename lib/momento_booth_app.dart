import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/transition_page.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/components/activity_monitor.dart';
import 'package:momento_booth/views/photo_booth_screen/photo_booth.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart' show WindowListener, windowManager;

part 'momento_booth_app.hotkeys.dart';
part 'momento_booth_app.routes.dart';

class MomentoBoothApp extends StatefulWidget {

  const MomentoBoothApp({super.key});

  @override
  State<MomentoBoothApp> createState() => _MomentoBoothAppState();

}

class _MomentoBoothAppState extends State<MomentoBoothApp> with WindowListener {

  final GoRouter _router = GoRouter(
    routes: [
      ShellRoute(
        routes: _rootRoutes,
        builder: (context, state, child) {
          return _HotkeyResponder(child: child);
        },
      )
    ],
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
    return Observer(
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
            Locale('de'), // German
          ],
          locale: getIt<SettingsManager>().settings.ui.language.toLocale(),
          builder: (context, child) {
            return ChangeNotifierProvider(create: (_) => ActivityMonitorController(), child: child);
          },
        );
      }
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
