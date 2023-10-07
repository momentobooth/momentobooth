import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

typedef GetValueCallback<T> = T Function();

class ComboBoxCard<TValue> extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final List<ComboBoxItem<TValue>> items;
  final GetValueCallback<TValue> value;
  final ValueChanged<TValue?> onChanged;

  const ComboBoxCard({
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
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150),
        child: Observer(builder: (_) {
          return ComboBox<TValue>(
            items: items,
            value: value(),
            onChanged: onChanged,
          );
        }),
      ),
    );
  }

}
