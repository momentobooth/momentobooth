import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/base/full_screen_dialog.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/photo_booth.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:window_manager/window_manager.dart' show WindowListener, windowManager;

part 'app.routes.dart';
part 'app.hotkeys.dart';

class Shell extends StatefulWidget {

  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();

}

class _ShellState extends State<Shell> with WindowListener {

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
      child:
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _menuBarWrapper(context, _router),
          Expanded(
            child: FluentApp.router(
              scrollBehavior: ScrollConfiguration.of(context),
              routerConfig: _router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FluentLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en')],
              locale: const Locale('en'),
            ),
          ),
        ],
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

Widget _menuBarWrapper(BuildContext context, GoRouter router) {
  return FluentTheme(data: FluentThemeData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: Color(0xFFFFFFFF),
        child: _menuBar(context, router)
      ),
    )
  );
}

Widget _menuBar(BuildContext context, GoRouter router) {
  return MenuBar(
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
  );
}
