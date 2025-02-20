import 'package:animations/animations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/onboarding_screen/pages/projects_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/settings_import_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/status_page.dart';
import 'package:momento_booth/views/onboarding_screen/pages/welcome_page.dart';

part 'onboarding_wizard.page_route.dart';
part 'onboarding_wizard.controller.dart';

class OnboardingWizard extends StatefulWidget {

  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();

}

class _OnboardingWizardState extends State<OnboardingWizard> {

  late final WizardController controller;

  @override
  void initState() {
    controller = WizardController([
      const WelcomePage(),
      const StatusPage(),
      const SettingsImportPage(),
      const ProjectsPage(),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: WizardProvider(
        controller: controller,
        child: Navigator(
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              _OnboardingPageRoute(
                builder: (context) => controller.pages[0],
              ),
            ];
          },
        ),
      ),
    );
  }

}
