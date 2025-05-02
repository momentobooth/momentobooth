part of 'project_settings.dart';

enum UiTheme {

  simple("Simple"),
  wedding("Wedding"),
  neobrutalism("Neobrutalism"),
  hollywood("Hollywood");

  final String name;

  const UiTheme(this.name);

  ThemeExtension get themeExtension {
    return switch (this) {
      UiTheme.simple => PhotoBoothTheme.defaultBasic(),
      UiTheme.wedding => PhotoBoothTheme.defaultWedding(),
      UiTheme.neobrutalism => PhotoBoothTheme.defaultNeobrutalism(),
      UiTheme.hollywood => PhotoBoothTheme.defaultHollywood(),
    };
  }

  ComboBoxItem<UiTheme> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<UiTheme>> asComboBoxItems() => UiTheme.values.map((value) => value.toComboBoxItem()).toList();

}
