import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';

class WizardPage extends StatelessWidget {

  final Widget child;

  const WizardPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (WizardProvider.of(context).canGoBack)
          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(left: 32, top: 24),
            child: IconButton(
              icon: Icon(LucideIcons.arrowLeft),
              onPressed: () => WizardProvider.of(context).previous(context),
            ),
          ),
        Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.only(right: 32, bottom: 24),
          child: FilledButton(
            onPressed: () {
              WizardProvider.of(context).next(context);
            },
            child: Text(WizardProvider.of(context).canGoNext ? "Next step" : "Finish"),
          ),
        ),
        child,
      ],
    );
  }

}
