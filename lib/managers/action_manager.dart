// import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/logger.dart';
// import 'package:action_manager/action_manager.dart';

part 'action_manager.g.dart';

class ActionManager = ActionManagerBase with _$ActionManager;

abstract class ActionManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Action manager";

  @readonly
  ObservableList<_Entry> _stack = ObservableList();

  List<AppAction> get current => _stack.isEmpty ? const [] : _stack.last.actions;

  MqttManager get mqtt => getIt<MqttManager>();

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  void initialize() {
    publish();
  }

  // /////// //
  // Methods //
  // /////// //

  void push(List<AppAction> actions, Object token) {
    _stack.add(_Entry(token, actions));
    publish();
  }

  void pop(Object token) {
    if (_stack.isNotEmpty) {
      _stack.removeWhere((entry) => entry.token == token);
      publish();
    } else {
      logWarning("Tried to pop from an empty action stack");
    }
  }

  void publish() {
    // Todo: Publish current action stack to MQTT
    logInfo("Stack of length ${_stack.length} contains ${current.length} actions: ${current.map((a) => a.name).join(", ")}");
  }

  void callAction(String actionName, {Map<String, dynamic> parameters = const {}}) {
    AppAction? action = current.firstWhereOrNull((a) => a.name == actionName);
    if (action != null) {
      logInfo("Calling action $actionName ${parameters.isNotEmpty ? "with parameters $parameters" : "without parameters"}");
      action.callback(parameters);
    } else {
      logWarning("Tried to call action $actionName, but it was not found in the current action stack");
    }
  }

}

class _Entry {
  final Object token;
  final List<AppAction> actions;

  _Entry(this.token, this.actions);
}
