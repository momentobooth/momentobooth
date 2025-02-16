import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/photo_booth_dialog_page.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/momento_booth_theme_data.dart';

/// This mixin makes several objects (that normally needs to be accessed using [BuildContext]) easier accessible from screen view models and controllers.
mixin BuildContextAbstractor {

  BuildContextAccessor get contextAccessor;
  BuildContext get _context => contextAccessor.buildContext;

  MomentoBoothThemeData get theme => _context.theme;
  GoRouter get router => _context.router;

  NavigatorState get navigator => _context.navigator;
  NavigatorState get rootNavigator => _context.rootNavigator;

  AppLocalizations get localizations => AppLocalizations.of(_context)!;

  Future<void> showUserDialog({required Widget dialog, required bool barrierDismissible}) async {
    await navigator.push(PhotoBoothDialogPage(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: dialog),
      ),
      barrierDismissible: barrierDismissible,
    ).createRoute(_context));
  }

}
