import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/action_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/photo_booth_dialog_page.dart';
import 'package:momento_booth/views/components/dialogs/dialog_actions_mixin.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

/// This mixin makes several objects (that normally needs to be accessed using [BuildContext]) easier accessible from screen view models and controllers.
mixin BuildContextAbstractor {

  BuildContextAccessor get contextAccessor;
  BuildContext get _context => contextAccessor.buildContext;

  PhotoBoothTheme get theme => _context.theme;
  GoRouter get router => _context.router;

  NavigatorState get navigator => _context.navigator;
  NavigatorState get rootNavigator => _context.rootNavigator;

  AppLocalizations get localizations => AppLocalizations.of(_context)!;

  /// Launches the given dialog widget as a dialog, and returns the result by the route `pop`.
  /// For stateless widgets implementing [DialogActionsMixin], use [publishActions] `true`, the dialog's actions will be published to the ActionManager for the duration of the dialog being open.
  /// For stateful widgets where the state implements [HasActionsMixin], the dialog will manage pushing and popping its own actions, so [publishActions] should be `false` to avoid extra scopes in the ActionManager.
  Future<T?> showUserDialog<T extends Object?>({required Widget dialog, required bool barrierDismissible, bool publishActions = true}) async {
    // We acquire the actions from the dialog and push them to the ActionManager
    final usedActionStackToken = Object();
    final List<AppAction> dialogActions = switch (dialog) {
      DialogActionsMixin photoBoothDialog => photoBoothDialog.actions,
      _ => [],
    };
    final String dialogScopeName = switch (dialog) {
      DialogActionsMixin photoBoothDialog => photoBoothDialog.scopeName,
      _ => "User Dialog",
    };
    if (publishActions) {
      getIt<ActionManager>().pushActions(dialogActions, dialogScopeName, usedActionStackToken);
    }
    // We then show the dialog and wait for it to be dismissed, saving the `pop` result
    final result = await navigator.push<T>(PhotoBoothDialogPage<T>(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: dialog),
      ),
      barrierDismissible: barrierDismissible,
    ).createRoute());
    // When the dialog is dismissed, we pop the actions from the ActionManager
    if (publishActions) {
      getIt<ActionManager>().pop(usedActionStackToken);
    }
    return result;
  }

}
