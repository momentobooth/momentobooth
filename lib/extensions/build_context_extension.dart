import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

extension BuildContextExtension on BuildContext {

  PhotoBoothTheme get theme => FluentTheme.of(this).photoBoothTheme;
  PhotoBoothTheme? get maybeTheme => FluentTheme.of(this).extension<PhotoBoothTheme>();
  NavigatorState get navigator => Navigator.of(this);
  NavigatorState get rootNavigator => Navigator.of(this, rootNavigator: true);
  GoRouter get router => GoRouter.of(this);
  AppLocalizations get localizations => AppLocalizations.of(this)!;

}
