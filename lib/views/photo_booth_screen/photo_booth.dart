import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/route_observer.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/components/config/set_scroll_configuration.dart';
import 'package:momento_booth/views/components/imaging/live_view_background.dart';
import 'package:momento_booth/views/photo_booth_screen/components/activity_monitor.dart';
import 'package:momento_booth/views/photo_booth_screen/components/framerate_monitor.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme_data.dart';

part 'photo_booth.hotkey_monitor.dart';
part 'photo_booth.routes.dart';

class PhotoBooth extends StatefulWidget {
  const PhotoBooth({super.key});

  @override
  State<StatefulWidget> createState() => PhotoBoothState();
}

class PhotoBoothState extends State<PhotoBooth> {
  final GoRouter _router = GoRouter(
    routes: _rootRoutes,
    observers: [GoRouterObserver(), HeroController()],
    initialLocation: StartScreen.defaultRoute,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _menuBar(context, _router),
          Expanded(
            child: FramerateMonitor(
              child: LiveViewBackground(
                router: _router,
                child: _HotkeyResponder(
                  router: _router,
                  child: ActivityMonitor(
                    router: _router,
                    child: MomentoBoothTheme(
                      data: MomentoBoothThemeData.defaults(),
                      child: SetScrollConfiguration(
                        child: Observer(
                          builder: (context) => FluentApp.router(
                            debugShowCheckedModeBanner: false,
                            scrollBehavior: ScrollConfiguration.of(context),
                            color: getIt<SettingsManager>().settings.ui.primaryColor,
                            theme: FluentThemeData(
                              accentColor: AccentColor.swatch(
                                {'normal': getIt<SettingsManager>().settings.ui.primaryColor},
                              ),
                            ),
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}

Widget _menuBar(BuildContext context, GoRouter router) {
  return ColoredBox(
    color: Color(0xFFFFFFFF),
    child: MenuBar(
      items: [
        MenuBarItem(title: 'File', items: [
          MenuFlyoutSubItem(
            text: const Text('Recent projects'),
            items: (context) {
              return [
                MenuFlyoutItem(
                  text: const Text('Plain Text Documents'),
                  onPressed: () {},
                ),
                MenuFlyoutItem(
                  text: const Text('Rich Text Documents'),
                  onPressed: () {},
                ),
                MenuFlyoutItem(
                  text: const Text('Other Formats'),
                  onPressed: () {},
                ),
              ];
            },
          ),
          MenuFlyoutItem(text: const Text('Open'), onPressed: getIt<ProjectManager>().browseOpen),
          MenuFlyoutItem(text: const Text('Settings'), onPressed: () { router.push("/settings"); }),
          const MenuFlyoutSeparator(),
          MenuFlyoutItem(text: const Text('Exit'), onPressed: () {}),
        ]),
        MenuBarItem(title: 'Edit', items: [
          MenuFlyoutItem(text: const Text('Undo'), onPressed: () {}),
          MenuFlyoutItem(text: const Text('Cut'), onPressed: () {}),
          MenuFlyoutItem(text: const Text('Copy'), onPressed: () {}),
          MenuFlyoutItem(text: const Text('Paste'), onPressed: () {}),
        ]),
        MenuBarItem(title: 'Help', items: [
          MenuFlyoutItem(text: const Text('About'), onPressed: () {}),
        ]),
      ],
    ),
  );
}
