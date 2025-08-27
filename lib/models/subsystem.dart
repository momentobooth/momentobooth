import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/logging.dart';

part 'subsystem.g.dart';

abstract class Subsystem = SubsystemBase with _$Subsystem;

abstract class SubsystemBase with Store, Logger {

  @readonly
  SubsystemStatus _subsystemStatus = const SubsystemStatus.initial();

  abstract String subsystemName;

  // ////////////// //
  // Initialization //
  // ////////////// //

  FutureOr<void> initialize() {}

  @nonVirtual
  Future<void> initializeSafe() async {
    try {
      await initialize();
      if (_subsystemStatus is SubsystemStatusInitial) reportSubsystemOk();
    } catch (e) {
      logError("Init of $runtimeType failed: $e");
      if (_subsystemStatus is SubsystemStatusInitial) reportSubsystemError(message: "Initialization error: $e");
    }
  }

  // /////////////////////// //
  // Report subsystem status //
  // /////////////////////// //

  @action
  void reportSubsystemBusy({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.busy(
      message: message,
      actions: actions,
    );
  }

  @action
  void reportSubsystemOk({String? message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.ok(
      message: message,
      actions: actions,
    );
  }

  @action
  void reportSubsystemDisabled({Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.disabled(
      actions: actions,
    );
  }

  @action
  void reportSubsystemWarning({required String message, String? exception, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.warning(
      message: message,
      actions: actions,
      exception: exception,
    );
  }

  @action
  void reportSubsystemError({required String message, String? exception, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.error(
      message: message,
      actions: actions,
      exception: exception,
    );
  }

  @action
  void reportSubsystemDeferred({required List<SubsystemStatus> children, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus = SubsystemStatus.deferred(
      children: children,
      actions: actions,
    );
  }

}
