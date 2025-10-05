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
import 'package:momento_booth/views/components/backgrounds/animated_circles_background.dart';
import 'package:momento_booth/views/components/indicators/onboarding_version_info.dart';
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';
import 'package:momento_booth/views/onboarding_screen/pages/error_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/finish_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/initialization_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/projects_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/settings_import_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/status_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/welcome_page.dart';
import 'package:wizard_router/wizard_router.dart';

class OnboardingScreen extends StatefulWidget {

  static const String defaultRoute = "/onboarding";

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

}

class _OnboardingScreenState extends State<OnboardingScreen> {

  late final WizardController _wizardController = WizardController(routes: {
    '/initialization-page': WizardRoute(builder: (context) => InitializationPage()),
    '/error-page': WizardRoute(builder: (context) => ErrorPage(), onLoad: (_) {
      return getIt<AppInitManager>().isSucceeded != true;
    }),
    '/welcome-page': WizardRoute(builder: (context) => WelcomePage(), onLoad: (_) {
      bool onboardingHasNewSteps = OnboardingStep.values.any((s) => !getIt<SettingsManager>().settings.onboardingStepsDone.contains(s));
      return onboardingHasNewSteps;
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

  @override
  void initState() {
    _autorunDispose = autorun((_) {
      if (getIt<AppInitManager>().isSucceeded != null) return _wizardController.replace();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        AnimatedCirclesBackground(),
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
    _autorunDispose();
    _wizardController.dispose();
    super.dispose();
  }

}
