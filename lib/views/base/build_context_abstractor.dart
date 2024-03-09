import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/photo_booth_dialog_page.dart';

mixin BuildContextAbstractor {

  BuildContextAccessor get contextAccessor;
  BuildContext get _context => contextAccessor.buildContext;

  MomentoBoothThemeData get theme => _context.theme;
  GoRouter get router => _context.router;

  NavigatorState get navigator => _context.navigator;
  NavigatorState get rootNavigator => _context.rootNavigator;

  AppLocalizations get localizations => AppLocalizations.of(_context)!;

  void showUserDialog(Widget child) {
    navigator.push(PhotoBoothDialogPage(
      key: null,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: child,
      ),
      barrierDismissible: true,
    ).createRoute(_context));
  }

}
