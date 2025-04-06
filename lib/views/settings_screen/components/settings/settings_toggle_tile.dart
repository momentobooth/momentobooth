import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/settings_screen/components/settings/settings_tile.dart';

class SettingsToggleTile extends StatelessWidget {

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.prefixWidget,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ValueGetter<bool> value;
  final ValueChanged<bool> onChanged;
  final Widget? prefixWidget;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      leading: prefixWidget,
      setting: Observer(builder: (_) {
        return ToggleSwitch(
          checked: value(),
          onChanged: onChanged,
        );
      }),
    );
  }

}
