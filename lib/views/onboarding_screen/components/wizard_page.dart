import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wizard_router/wizard_router.dart';

class WizardPage extends StatelessWidget {

  final Widget child;
  final bool showBackAction;
  final bool showNextAction;

  const WizardPage({super.key, this.showBackAction = true, this.showNextAction = true, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(left: 32, top: 24),
          child: Visibility.maintain(
            visible: Wizard.of(context).hasPrevious && showBackAction,
            child: IconButton(
              icon: Icon(LucideIcons.arrowLeft),
              onPressed: Wizard.of(context).back,
            ),
          ),
        ),
        Expanded(child: child),
        Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.only(right: 32, bottom: 24),
          child: showNextAction ? FilledButton(
            onPressed: () => Wizard.of(context).next(),
            child: Text("Next step"),
          ) : null,
        ),
      ],
    );
  }

}
