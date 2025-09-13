import 'package:animations/animations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show PageTransitionsTheme, Theme, ThemeData;
import 'package:momento_booth/views/components/backgrounds/animated_circles_background.dart';
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';
import 'package:momento_booth/views/onboarding_screen/pages/projects_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/settings_import_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/status_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/welcome_page.dart';
import 'package:wizard_router/wizard_router.dart';

class OnboardingScreen extends StatelessWidget {

  static const String defaultRoute = "/onboarding";

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        AnimatedCirclesBackground(),
        Center(
          child: OnboardingWizard(
            child: Theme(
              data: ThemeData(
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: {
                    defaultTargetPlatform: SharedAxisPageTransitionsBuilder(
                      transitionType: SharedAxisTransitionType.horizontal,
                      fillColor: Colors.transparent,
                    ),
                  },
                ),
              ),
              child: Wizard(
                routes: {
                  '/welcome-page': WizardRoute(builder: (context) => WelcomePage()),
                  '/status-page': WizardRoute(builder: (context) => StatusPage()),
                  '/settings-import-page': WizardRoute(builder: (context) => SettingsImportPage()),
                  '/projects-page': WizardRoute(builder: (context) => ProjectsPage()),
                },
              ),
            ),
          ),
        ),
        // FIXME: Crashes due to info not initialized yet
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: OnboardingVersionInfo(
        //     appVersionInfo: _appVersionInfo,
        //   ),
        // ),
      ],
    );
  }

}
