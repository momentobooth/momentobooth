import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';

class SettingsActionTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: Button(
        onPressed: onPressed,
        child: Text(buttonText),
      ),
    );
  }

}
