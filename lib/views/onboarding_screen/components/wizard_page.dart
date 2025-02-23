import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:wizard_router/wizard_router.dart';

class WizardPage extends StatelessWidget {

  final Widget child;

  const WizardPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Wizard.of(context).hasPrevious)
          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(left: 32, top: 24),
            child: IconButton(
              icon: Icon(LucideIcons.arrowLeft),
              onPressed: Wizard.of(context).back,
            ),
          ),
        Expanded(child: child),
        Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.only(right: 32, bottom: 24),
          child: FilledButton(
            onPressed: () {
              if (Wizard.of(context).hasNext) {
                Wizard.of(context).next();
              } else {
                context.replace(StartScreen.defaultRoute);
              }
            },
            child: Text(Wizard.of(context).hasNext ? "Next step" : "Finish"),
          ),
        ),
      ],
    );
  }

}
