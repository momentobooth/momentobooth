import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/logger.dart';

mixin Subsystem on Logger {

  final Observable<SubsystemStatus> _subsystemStatus = Observable(const SubsystemStatus.initial());

  SubsystemStatus get subsystemStatus => _subsystemStatus.value;

  // ////////////// //
  // Initialization //
  // ////////////// //

  FutureOr<void> initialize() {}

  @nonVirtual
  Future<void> initializeSafe() async {
    try {
      await initialize();
      Action(() => _subsystemStatus.value = const SubsystemStatus.ok());
    } catch (e, s) {
      logError("Init of $runtimeType failed", e, s);
      Action(() => _subsystemStatus.value = SubsystemStatus.error(message: "Initialization error: $e"));
    }
  }

  // /////////////////////// //
  // Report subsystem status //
  // /////////////////////// //

  void reportSubsystemBusy({required String message, Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.busy(
        message: message,
        actions: actions,
      );
    });
  }

  void reportSubsystemOk({String? message, Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.ok(
        message: message,
        actions: actions,
      );
    });
  }

  void reportSubsystemDisabled({Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.disabled(
        actions: actions,
      );
    });
  }

  void reportSubsystemWarning({required String message, Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.busy(
        message: message,
        actions: actions,
      );
    });
  }

  void reportSubsystemError({required String message, Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.error(
        message: message,
        actions: actions,
      );
    });
  }

  void reportSubsystemDeferred({required List<SubsystemStatus> children, Map<String, Future Function()> actions = const {}}) {
    Action(() {
      _subsystemStatus.value = SubsystemStatus.deferred(
        children: children,
        actions: actions,
      );
    });
  }

}
