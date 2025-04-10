import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

extension BuildContextExtension on BuildContext {

  MomentoBoothThemeData get legacyTheme => MomentoBoothTheme.of(this).data;
  PhotoBoothTheme get theme => FluentTheme.of(this).photoBoothTheme;
  NavigatorState get navigator => Navigator.of(this);
  NavigatorState get rootNavigator => Navigator.of(this, rootNavigator: true);
  GoRouter get router => GoRouter.of(this);

}
