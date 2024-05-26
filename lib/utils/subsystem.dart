import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/logger.dart';

mixin Subsystem on Logger {

  final Observable<SubsystemStatus> _subsystemStatus = Observable(const SubsystemStatus.busy(message: ""));

  SubsystemStatus get subsystemStatus => _subsystemStatus.value;

  // ////////////// //
  // Initialization //
  // ////////////// //

  FutureOr<SubsystemStatus?> initializeSubsystem() {
    return null;
  }

  Future<void> initialize() async {
    SubsystemStatus? result;
    try {
      result = await initializeSubsystem() ?? const SubsystemStatus.ok();
    } catch (e, s) {
      logError("Init of $runtimeType failed", e, s);
      result = SubsystemStatus.error(message: "Initialization error: $e");
    }
    _subsystemStatus.value = result;
  }

  // /////////////////////// //
  // Report subsystem status //
  // /////////////////////// //

  void reportSubsystemBusy({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.busy(
      message: message,
      actions: actions,
    );
  }

  void reportSubsystemOk({Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.ok(
      actions: actions,
    );
  }

  void reportSubsystemDisabled({Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.disabled(
      actions: actions,
    );
  }

  void reportSubsystemWarning({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.busy(
      message: message,
      actions: actions,
    );
  }

  void reportSubsystemError({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.error(
      message: message,
      actions: actions,
    );
  }

  void reportSubsystemDeferred({required List<SubsystemStatus> children, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.deferred(
      children: children,
      actions: actions,
    );
  }

}
