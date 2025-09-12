part of 'project_settings.dart';

enum UiTheme {

  simple("Simple"),
  hollywood("Hollywood");

  final String name;

  const UiTheme(this.name);

  ThemeExtension themeExtension({required Color primaryColor}) {
    return switch (this) {
      UiTheme.simple => PhotoBoothTheme.defaultBasic(primaryColor: primaryColor),
      UiTheme.hollywood => PhotoBoothTheme.defaultHollywood(primaryColor: primaryColor),
    };
  }

  ComboBoxItem<UiTheme> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<UiTheme>> asComboBoxItems() => UiTheme.values.map((value) => value.toComboBoxItem()).toList();

}

enum CollageMode {

  userSelection(4, "User choice of pictures"),
  twoLayout(2, "Two picture layout"),
  threeLayout(3, "Three picture layout"),
  fourLayout(4, "Four picture layout");

  final int captureCount;
  final String name;

  const CollageMode(this.captureCount, this.name);

  ComboBoxItem<CollageMode> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<CollageMode>> asComboBoxItems() => CollageMode.values.map((value) => value.toComboBoxItem()).toList();

}
