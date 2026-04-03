// import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/models/app_action_call.dart';
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
  ObservableMap<DateTime, AppActionCall> actionHistory = ObservableMap();

  List<AppAction> get current => _stack.isEmpty ? const [] : _stack.last.actions;
  List<String> get currentScopes => _stack.isEmpty ? const [] : _stack.map((e) => e.scopeName).toList();

  bool get allowControl => getIt<SettingsManager>().settings.control.enable;

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

  void registerActionCall(AppActionCall call, {bool overwriteSameName = false}) {
    final lastEntry = actionHistory.entries.last;
    if (lastEntry.value.tool == call.tool && overwriteSameName) {
      logInfo("Overwriting previous action call for tool ${call.tool} with arguments ${lastEntry.value.arguments} by ${call.arguments}");
      actionHistory.remove(lastEntry.key);
    }
    actionHistory[DateTime.now()] = call;
    final retentionLength = getIt<SettingsManager>().settings.control.controlHistoryDurationSeconds;
    actionHistory.removeWhere((key, value) => key.isBefore(DateTime.now().subtract(Duration(seconds: retentionLength))));
    logInfo("Registered action call for tool ${call.tool} with arguments ${call.arguments}. Action history now contains ${actionHistory.length} entries.");
  }

  void pushActions(List<AppAction> actions, String scopeName, Object token) {
    _stack.add(_Entry(token, scopeName, actions));
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
    if (!allowControl) {
      logWarning("Received request to call action $actionName, but control is disabled in settings");
      return;
    }
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
  final String scopeName;
  final List<AppAction> actions;

  _Entry(this.token, this.scopeName, this.actions);
}
