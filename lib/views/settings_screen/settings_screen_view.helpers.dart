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
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: 150),
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

FluentSettingCard _getInput<T extends num>({
  required IconData icon,
  required String title,
  required String subtitle,
  required GetValueCallback<T> value,
  required ValueChanged<T?> onChanged,
  num smallChange = 1,
}) {
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: SizedBox(
      width: 150,
      child: Observer(builder: (_) {
        return NumberBox<T>(
          value: value(),
          onChanged: onChanged,
          smallChange: smallChange,
        );
      }),
    ),
  );
}



FluentSettingCard _getTextInput({
  required IconData icon,
  required String title,
  required String subtitle,
  required TextEditingController controller,
  required ValueChanged<String?> onChanged,
}) {
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: SizedBox(
      width: 250,
      child: TextBox(
        controller: controller,
        onChanged: onChanged,
        // Todo: See if there is a better way to fire onChanged instead of every button press.
      ),
    ),
  );
}
