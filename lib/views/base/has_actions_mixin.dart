import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/action_manager.dart';
import 'package:momento_booth/models/app_action.dart';

mixin HasActionsMixin {
  final Object _actionStackToken = Object();
  List<AppAction> get actions => [];
  String get scopeName => "Unknown";

  void pushActions() {
    getIt<ActionManager>().pushActions(actions, scopeName, _actionStackToken);
  }

  void popActions() {
    getIt<ActionManager>().pop(_actionStackToken);
  }
}
