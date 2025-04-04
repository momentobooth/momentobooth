import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/photo_booth_dialog_page.dart';
import 'package:momento_booth/views/base/transition_page.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/photo_booth_shell.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Shell,Route')
class AppRouter extends RootStackRouter {


  @override
  List<AutoRoute> get routes => [
    TransitionPage.fromSettings(page: OnboardingRoute.page, initial: true),
    TransitionPage.fromSettings(page: SettingsRoute.page, opaque: false, barrierDismissible: true, enableTransitionOut: false),
    TransitionPage.fromSettings(
      page: PhotoBoothRoute.page,
      enableTransitionOut: false,
      children: [
        TransitionPage.fromSettings(page: StartRoute.page),
        TransitionPage.fromSettings(page: ChooseCaptureModeRoute.page),
        TransitionPage.fromSettings(page: SingleCaptureRoute.page),
        TransitionPage.fromSettings(page: MultiCaptureRoute.page),
        TransitionPage.fromSettings(page: CollageMakerRoute.page),
        TransitionPage.fromSettings(page: ShareRoute.page),
        TransitionPage.fromSettings(page: GalleryRoute.page),
        TransitionPage.fromSettings(page: PhotoDetailsRoute.page),
        TransitionPage.fromSettings(page: ManualCollageRoute.page),
      ],
    ),
  ];

}
