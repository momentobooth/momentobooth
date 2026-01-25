import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show PageTransitionsTheme, Theme, ThemeData;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/app_init_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/views/components/indicators/onboarding_version_info.dart';
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';
import 'package:momento_booth/views/onboarding_screen/pages/error_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/finish_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/imaging_device_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/initialization_page.dart';
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

  late final Timer _timer;
  final Random _random = Random();

  late final WizardController _wizardController = WizardController(routes: {
    '/initialization-page': WizardRoute(builder: (context) => InitializationPage()),
    '/error-page': WizardRoute(builder: (context) => ErrorPage(), onLoad: (_) {
      return getIt<AppInitManager>().isSucceeded != true;
    }),
    '/welcome-page': WizardRoute(builder: (context) => WelcomePage(), onLoad: (_) {
      bool onboardingHasNewSteps = OnboardingStep.values.any((s) => !getIt<SettingsManager>().settings.onboardingStepsDone.contains(s));
      return onboardingHasNewSteps;
    }),
    '/imaging-device-page': WizardRoute(builder: (context) => ImagingDevicePage(), onLoad: (_) {
      return !getIt<SettingsManager>().settings.onboardingStepsDone.contains(OnboardingStep.setupImagingDevice);
    }),
    '/status-page': WizardRoute(builder: (context) => StatusPage(), onLoad: (_) {
      final allSubsystemsAreOk = getIt<ObservableList<Subsystem>>()
            .map((s) => s.subsystemStatus)
            .every((s) {
              return s is SubsystemStatusOk || s is SubsystemStatusDisabled;
            });
      return !allSubsystemsAreOk;
    }),
    '/settings-import-page': WizardRoute(builder: (context) => SettingsImportPage(), onLoad: (_) {
      return !getIt<SettingsManager>().settings.onboardingStepsDone.contains(OnboardingStep.importSettings);
    }),
    '/projects-page': WizardRoute(builder: (context) => ProjectsPage(), onLoad: (_) {
      return !getIt<SettingsManager>().settings.onboardingStepsDone.contains(OnboardingStep.openProject);
    }),
    '/finish': WizardRoute(builder: (context) => FinishPage(), onLoad: (_) {
      getIt<SettingsManager>().mutateAndSave((s) => s.copyWith(
        onboardingStepsDone: { ...s.onboardingStepsDone, ...OnboardingStep.values },
      ));
      return true;
    }),
  });

  late final ReactionDisposer _autorunDispose;

  late List<Gradient> _gradients;

  @override
  void initState() {
    _updateGradients();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateGradients(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _updateGradients());
    _autorunDispose = autorun((_) {
      if (getIt<AppInitManager>().isSucceeded != null) return _wizardController.replace();
    });

    super.initState();
  }

  void _updateGradients() {
    if (!mounted) return;
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
          colors: [_getRandomLightBlueTint(), const Color.fromARGB(0, 255, 255, 255)],
        ),
        growable: false,
      );
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
              decoration: BoxDecoration(gradient: g),
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
                child: Wizard(controller: _wizardController),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Observer(
            builder: (context) {
              if (getIt<AppInitManager>().isSucceeded != true) return const SizedBox();
              return OnboardingVersionInfo(appVersionInfo: appVersionInfo);
            }
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _autorunDispose();
    _wizardController.dispose();
    super.dispose();
  }

}
