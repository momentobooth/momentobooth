import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_value_chip.dart';

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
      setting: SettingsValueChip(text: text),
    );
  }

}
