import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

class PasswordInputCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String?> onFinishedEditing;

  const PasswordInputCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onFinishedEditing,
  });

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: SizedBox(
        width: 250,
        child: Focus(
          skipTraversal: true,
          onFocusChange: (hasFocus) => !hasFocus ? onFinishedEditing(controller.text) : null,
          child: PasswordBox(
            controller: controller,
            revealMode: PasswordRevealMode.peekAlways,
          ),
        ),
      ),
    );
  }

}
