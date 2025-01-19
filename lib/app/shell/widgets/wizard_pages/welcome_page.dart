import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/app/shell/widgets/wizard.dart';

class WelcomePage extends StatelessWidget {

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.only(right: 32, bottom: 24),
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
