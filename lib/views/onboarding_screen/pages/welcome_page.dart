import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';

class WelcomePage extends StatelessWidget {

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      showBackAction: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            spacing: 32,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/svg/logo.svg'),
              Text("You're here, awesome! Now let's make memories <3"),
            ],
          ),
        ],
      ),
    );
  }

}
