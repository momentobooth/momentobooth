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
      reportSubsystemOk();
    } catch (e, s) {
      logError("Init of $runtimeType failed", e, s);
      reportSubsystemError(message: "Initialization error: $e");
    }
  }

  // /////////////////////// //
  // Report subsystem status //
  // /////////////////////// //

  Action? _reportSubsystemBusy;

  void reportSubsystemBusy({required String message, Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemBusy ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.busy(
        message: message,
        actions: actions,
      );
    }))();
  }

  Action? _reportSubsystemOk;

  void reportSubsystemOk({String? message, Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemOk ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.ok(
        message: message,
        actions: actions,
      );
    }))();
  }

  Action? _reportSubsystemDisabled;

  void reportSubsystemDisabled({Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemDisabled ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.disabled(
        actions: actions,
      );
    }))();
  }

  Action? _reportSubsystemWarning;

  void reportSubsystemWarning({required String message, Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemWarning ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.busy(
        message: message,
        actions: actions,
      );
    }))();
  }

  Action? _reportSubsystemError;

  void reportSubsystemError({required String message, Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemError ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.error(
        message: message,
        actions: actions,
      );
    }))();
  }

  Action? _reportSubsystemDeferred;

  void reportSubsystemDeferred({required List<SubsystemStatus> children, Map<String, Future Function()> actions = const {}}) {
    (_reportSubsystemDeferred ??= Action(() {
      _subsystemStatus.value = SubsystemStatus.deferred(
        children: children,
        actions: actions,
      );
    }))();
  }

}
