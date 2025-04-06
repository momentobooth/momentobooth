import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/settings_screen/components/settings/settings_tile.dart';

class SettingsComboBoxTile<TValue> extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final List<ComboBoxItem<TValue>> items;
  final ValueGetter<TValue> value;
  final ValueChanged<TValue?> onChanged;

  const SettingsComboBoxTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: Observer(builder: (_) {
        return SizedBox(
          height: 34,
          child: ComboBox<TValue>(
            items: items,
            value: value(),
            onChanged: onChanged,
          ),
        );
      }),
    );
  }

}
