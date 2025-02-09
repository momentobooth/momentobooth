import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/window_manager.dart';
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
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Observer(
            builder: (context) => !getIt<WindowManager>().isFullScreen ? _menuBar(context, _router) : SizedBox()
          ),
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
                            color: getIt<ProjectManager>().settings.primaryColor,
                            theme: FluentThemeData(
                              accentColor: AccentColor.swatch(
                                {'normal': getIt<ProjectManager>().settings.primaryColor},
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
                for (final project in getIt<ProjectManager>().listProjects())
                  MenuFlyoutItem(
                    text: Text(project.name),
                    onPressed: () { getIt<ProjectManager>().open(project.path); },
                  ),
              ];
            },
          ),
          MenuFlyoutItem(text: const Text('Open project'), onPressed: getIt<ProjectManager>().browseOpen, leading: Icon(LucideIcons.folderInput), trailing: shortcut("Ctrl+O")),
          MenuFlyoutItem(text: const Text('View project in explorer'), onPressed: () {
            final uri = Uri.parse("file:///${getIt<ProjectManager>().path!.path}");
            launchUrl(uri);
          }, leading: Icon(LucideIcons.folderClosed)),
          MenuFlyoutItem(text: const Text('Settings'), onPressed: () { GoRouter.of(context).push(SettingsScreen.defaultRoute); }, leading: Icon(LucideIcons.settings), trailing: shortcut("Ctrl+S")),
          MenuFlyoutItem(text: const Text('Restore live view'), onPressed: () { getIt<LiveViewManager>().restoreLiveView(); }, leading: Icon(LucideIcons.rotateCcw), trailing: shortcut("Ctrl+R")),
          const MenuFlyoutSeparator(),
          MenuFlyoutItem(text: const Text('Exit'), onPressed: getIt<WindowManager>().close,)
        ]),
        MenuBarItem(title: 'View', items: [
          MenuFlyoutItem(text: const Text('Full screen'), onPressed: () { getIt<WindowManager>().toggleFullscreen(); }, leading: Icon(LucideIcons.expand), trailing: shortcut("Ctrl+F/Alt+Enter")),
          const MenuFlyoutSeparator(),
          MenuFlyoutItem(text: const Text('Start screen'), onPressed: () { router.go(StartScreen.defaultRoute); }, leading: Icon(LucideIcons.play), trailing: shortcut("Ctrl+H")),
          MenuFlyoutItem(text: const Text('Gallery'), onPressed: () { router.go(GalleryScreen.defaultRoute); }, leading: Icon(LucideIcons.images)),
          MenuFlyoutItem(text: const Text('Manual collage'), onPressed: () { router.go(ManualCollageScreen.defaultRoute); }, leading: Icon(LucideIcons.layoutDashboard), trailing: shortcut("Ctrl+M")),
        ]),
        MenuBarItem(title: 'Help', items: [
          MenuFlyoutItem(text: const Text('Documentation'), onPressed: () { launchUrl(Uri.parse("https://momentobooth.github.io/momentobooth/")); }, leading: Icon(LucideIcons.book)),
          // TODO go to about screen in settings
          MenuFlyoutItem(text: const Text('About'), onPressed: () { GoRouter.of(context).push(SettingsScreen.defaultRoute); }, leading: Icon(LucideIcons.info)),
        ]),
      ],
    ),
  );
}

Widget shortcut(String shortcut) {
  return Text(shortcut, style: TextStyle(color: Color.fromARGB(255, 128, 128, 128)),);
}
