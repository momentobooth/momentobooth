part of 'settings_screen_view.dart';

typedef GetValueCallback<T> = T Function();

FluentSettingCard _getComboBoxCard<TValue>({
  required IconData icon,
  required String title,
  required String subtitle,
  required List<ComboBoxItem<TValue>> items,
  required GetValueCallback<TValue> value,
  required ValueChanged<TValue?> onChanged,
}) {
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: Observer(builder: (_) {
      return ComboBox<TValue>(
        items: items,
        value: value(),
        onChanged: onChanged,
      );
    }),
  );
}

FluentSettingCard _getInput({
  required IconData icon,
  required String title,
  required String subtitle,
  required GetValueCallback<int> value,
  required ValueChanged<int?> onChanged,
}) {
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: SizedBox(
      width: 150,
      child: Observer(builder: (_) {
        return NumberBox(
          value: value(),
          onChanged: onChanged,
        );
      }),
    ),
  );
}
