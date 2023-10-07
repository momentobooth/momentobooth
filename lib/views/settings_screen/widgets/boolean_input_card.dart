import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

typedef GetValueCallback<T> = T Function();

class BooleanInputCard extends StatelessWidget {

  const BooleanInputCard({
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
  final GetValueCallback<bool> value;
  final ValueChanged<bool> onChanged;
  final Widget? prefixWidget;

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      prefixWidget: prefixWidget,
      child: Observer(builder: (_) {
        return ToggleSwitch(
          checked: value(),
          onChanged: onChanged,
        );
      }),
    );
  }

}
