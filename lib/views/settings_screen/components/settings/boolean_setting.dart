import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/settings_screen/components/settings/setting.dart';

class BooleanSetting extends StatelessWidget {

  const BooleanSetting({
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
    return Setting(
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
