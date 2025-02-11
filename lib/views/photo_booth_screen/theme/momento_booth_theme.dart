import 'package:flutter/material.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme_data.dart';

class MomentoBoothTheme extends InheritedWidget {

  final MomentoBoothThemeData data;

  const MomentoBoothTheme({
    super.key,
    required super.child,
    required this.data,
  });

  static MomentoBoothTheme of(BuildContext context) {
    MomentoBoothTheme? theme = context.dependOnInheritedWidgetOfExactType<MomentoBoothTheme>();
    assert(theme != null, "MomentoBoothTheme is not available");
    return theme!;
  }

  @override
  bool updateShouldNotify(MomentoBoothTheme oldWidget) {
    return data != oldWidget.data;
  }

}
