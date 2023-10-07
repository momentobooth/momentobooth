part of 'settings_screen_view.dart';

typedef GetValueCallback<T> = T Function();

FluentSettingCard _getButtonCard<TValue>({
  required IconData icon,
  required String title,
  required String subtitle,
  required String buttonText,
  required VoidCallback onPressed,
}) {
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: Button(
        onPressed: onPressed,
        child: Text(buttonText),
      ),
    ),
  );
}

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

FluentSettingCard _getPasswordInput({
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
      child: PasswordBox(
        controller: controller,
        onChanged: onChanged,
        revealMode: PasswordRevealMode.peekAlways,
        // Todo: See if there is a better way to fire onChanged instead of every button press.
      ),
    ),
  );
}

FluentSettingCard _getBooleanInput({
  required IconData icon,
  required String title,
  required String subtitle,
  required GetValueCallback<bool> value,
  required ValueChanged<bool> onChanged,
  Widget? prefixWidget,
}) {
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

FluentSettingCard _getFolderPickerCard<TValue>({
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
    child: Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.folder, size: 24.0),
          onPressed: () async {
            String? selectedDirectory = await getDirectoryPath(initialDirectory: controller.text);
            if (selectedDirectory == null) return;
            controller.text = selectedDirectory;
            onChanged(selectedDirectory);
          },
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150),
          child: SizedBox(
            width: 250,
            child: TextBox(
              readOnly: true,
              controller: controller,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

FluentSettingCard _getTextDisplay({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required String text,
}) {
  FluentThemeData themeData = FluentTheme.of(context);
  return FluentSettingCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    child: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: themeData.accentColor,
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
