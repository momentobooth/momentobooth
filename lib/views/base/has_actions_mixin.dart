import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/action_manager.dart';
import 'package:momento_booth/models/app_action.dart';

mixin HasActionsMixin {
  final Object _actionStackToken = Object();
  List<AppAction> get actions => [];

  void pushActions() {
    getIt<ActionManager>().push(actions, _actionStackToken);
  }

  void popActions() {
    getIt<ActionManager>().pop(_actionStackToken);
  }
}
