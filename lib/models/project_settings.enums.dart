part of 'project_settings.dart';

enum UiTheme {

  simple("Simple"),
  wedding("Wedding"),
  neobrutalism("Neobrutalism"),
  hollywood("Hollywood");

  final String name;

  const UiTheme(this.name);

  ThemeExtension themeExtension({required Color primaryColor}) {
    return switch (this) {
      UiTheme.simple => PhotoBoothTheme.defaultBasic(primaryColor: primaryColor),
      UiTheme.wedding => PhotoBoothTheme.defaultWedding(primaryColor: primaryColor),
      UiTheme.neobrutalism => PhotoBoothTheme.defaultNeobrutalism(primaryColor: primaryColor),
      UiTheme.hollywood => PhotoBoothTheme.defaultHollywood(primaryColor: primaryColor),
    };
  }

  ComboBoxItem<UiTheme> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<UiTheme>> asComboBoxItems() => UiTheme.values.map((value) => value.toComboBoxItem()).toList();

}
