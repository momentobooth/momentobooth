import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/subsystem_status.dart';

mixin Subsystem {

  final Observable<SubsystemStatus> _subsystemStatus = Observable(const SubsystemStatus.busy(message: ""));

  SubsystemStatus get subsystemStatus => _subsystemStatus.value;

  void reportBusy({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.busy(
      message: message,
      actions: actions,
    );
  }

  void reportOk({Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.ok(
      actions: actions,
    );
  }

  void reportDisabled({Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.disabled(
      actions: actions,
    );
  }

  void reportWarning({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.busy(
      message: message,
      actions: actions,
    );
  }

  void reportError({required String message, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.error(
      message: message,
      actions: actions,
    );
  }

  void reportDefer({required List<SubsystemStatus> children, Map<String, Future Function()> actions = const {}}) {
    _subsystemStatus.value = SubsystemStatus.deferred(
      children: children,
      actions: actions,
    );
  }

}
