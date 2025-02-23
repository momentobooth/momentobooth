import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show PageTransitionsTheme, Theme, ThemeData;
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';
import 'package:momento_booth/views/onboarding_screen/pages/projects_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/settings_import_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/status_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/welcome_page.dart';
import 'package:wizard_router/wizard_router.dart';

class OnboardingScreen extends StatefulWidget {

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

}

class _OnboardingScreenState extends State<OnboardingScreen> {

  static const int _gradientCount = 3;

  final _random = Random();
  late List<Gradient> _gradients;

  @override
  void initState() {
    _updateGradients();

    Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateGradients(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _updateGradients());

    super.initState();
  }

  void _updateGradients() {
    setState(() {
      _gradients = List.generate(
          _gradientCount,
          (i) => RadialGradient(
                radius: _random.nextDouble() / 3 + 0.30,
                center: Alignment(
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                ),
                focalRadius: 100,
                colors: [
                  _getRandomLightBlueTint(),
                  const Color.fromARGB(0, 255, 255, 255),
                ],
              ),
          growable: false);
    });
  }

  Color _getRandomLightBlueTint() {
    final possibleColors = [Colors.blue.light, Colors.blue.lightest];
    final chosenColor = possibleColors[_random.nextInt(possibleColors.length)];
    return chosenColor.withValues(alpha: _random.nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        ..._gradients.map((g) => AnimatedContainer(
              duration: const Duration(seconds: 10),
              decoration: BoxDecoration(
                gradient: g,
              ),
            )),
        Center(
          child: SizedBox(
            width: 800,
            height: 500,
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
