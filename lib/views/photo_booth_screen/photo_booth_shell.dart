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
import 'package:momento_booth/views/base/custom_shell_route_data.dart';
import 'package:momento_booth/views/components/config/set_scroll_configuration.dart';
import 'package:momento_booth/views/components/imaging/live_view_background.dart';
import 'package:momento_booth/views/photo_booth_screen/components/activity_monitor.dart';
import 'package:momento_booth/views/photo_booth_screen/components/framerate_monitor.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

part 'photo_booth_shell.hotkey_monitor.dart';
part 'photo_booth_shell.menu.dart';

part 'photo_booth_shell.g.dart';

@TypedShellRoute<PhotoBoothRoute>(routes: [
  TypedGoRoute<StartRoute>(path: '/start'),
  TypedGoRoute<ChooseCaptureModeRoute>(path: '/choose_capture_mode'),
  TypedGoRoute<SingleCaptureRoute>(path: '/single-capture'),
  TypedGoRoute<MultiCaptureRoute>(path: '/multi-capture'),
  TypedGoRoute<CollageMakerRoute>(path: '/collage-maker'),
  TypedGoRoute<ShareRoute>(path: '/share'),
  TypedGoRoute<GalleryRoute>(path: '/gallery'),
  TypedGoRoute<PhotoDetailsRoute>(path: '/photo-details'),
  TypedGoRoute<ManualCollageRoute>(path: '/manual-collage'),
])
class PhotoBoothRoute extends CustomShellRouteData {

  const PhotoBoothRoute() : super(enableTransitionOut: false);

  static final List<NavigatorObserver> $observers = [GoRouterObserver()];

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) => PhotoBoothShell(child: navigator);

}

class PhotoBoothShell extends StatelessWidget {

  final Widget child;

  const PhotoBoothShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Observer(
          builder: (context) => !getIt<WindowManager>().isFullScreen ? MomentoMenuBar() : SizedBox.shrink()
        ),
        Expanded(
          child: FramerateMonitor(
            child: LiveViewBackground(
              child: _HotkeyResponder(
                child: ActivityMonitor(
                  child: MomentoBoothTheme(
                    data: MomentoBoothThemeData.defaults(),
                    child: SetScrollConfiguration(
                      child: Observer(
                        builder: (context) => FluentApp(
                          debugShowCheckedModeBanner: false,
                          scrollBehavior: ScrollConfiguration.of(context),
                          color: getIt<ProjectManager>().settings.primaryColor,
                          theme: FluentThemeData(
                            accentColor: AccentColor.swatch(
                              {'normal': getIt<ProjectManager>().settings.primaryColor},
                            ),
                          ),
                          localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                            FluentLocalizations.delegate,
                          ],
                          supportedLocales: const [Locale('en'), Locale('nl')],
                          locale: getIt<SettingsManager>().settings.ui.language.toLocale(),
                          home: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
