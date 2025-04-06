import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_screen/components/settings/setting.dart';

class PasswordSetting extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String?> onFinishedEditing;

  const PasswordSetting({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onFinishedEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Setting(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: SizedBox(
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
