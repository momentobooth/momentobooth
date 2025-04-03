import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/photo_booth_shell/theme/momento_booth_theme.dart';
import 'package:momento_booth/views/photo_booth_shell/theme/momento_booth_theme_data.dart';

extension BuildContextExtension on BuildContext {

  MomentoBoothThemeData get theme => MomentoBoothTheme.of(this).data;
  NavigatorState get navigator => Navigator.of(this);
  NavigatorState get rootNavigator => Navigator.of(this, rootNavigator: true);

}
