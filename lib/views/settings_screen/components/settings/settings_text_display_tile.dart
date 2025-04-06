import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_screen/components/settings/settings_tile.dart';

class SettingsTextDisplayTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String text;

  const SettingsTextDisplayTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).accentColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

}
