import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/app_init_manager.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';

class InitializationPage extends StatelessWidget {

  const InitializationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      showNextAction: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Observer(
            builder: (context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressRing(),
                  const SizedBox(height: 16),
                  Text(getIt<AppInitManager>().status),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

}
