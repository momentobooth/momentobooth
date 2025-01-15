import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/app/shell/widgets/wizard.dart';

class WelcomePage extends StatelessWidget {

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 64,
      children: [
        Expanded(
          child: Column(
            children: [
              SvgPicture.asset('assets/svg/logo.svg'),
              Text("You're here, awesome! Now let's make memories <3"),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: FilledButton(
            onPressed: () {
              WizardProvider.of(context).next(context);
            },
            child: Text("Continue to app"),
          ),
        ),
      ],
    );
  }

}
