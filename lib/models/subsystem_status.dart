import 'package:freezed_annotation/freezed_annotation.dart';

part 'subsystem_status.freezed.dart';

typedef ActionMap = Map<String, Future Function()>;

@freezed
class SubsystemStatus with _$SubsystemStatus {

  const SubsystemStatus._();

  const factory SubsystemStatus.busy({
    required String message,
    @Default({}) ActionMap actions,
  }) = SubsystemStatusBusy;

  const factory SubsystemStatus.ok({
    String? message,
    @Default({}) ActionMap actions,
  }) = SubsystemStatusOk;

  const factory SubsystemStatus.disabled({
    @Default({}) ActionMap actions,
  }) = SubsystemStatusDisabled;

  const factory SubsystemStatus.warning({
    required String message,
    @Default({}) ActionMap actions,
  }) = SubsystemStatusWarning;

  const factory SubsystemStatus.error({
    required String message,
    @Default({}) ActionMap actions,
  }) = SubsystemStatusError;

  const factory SubsystemStatus.deferred({
    required List<SubsystemStatus> children,
    @Default({}) ActionMap actions,
  }) = SubsystemStatusWithChildren;

}
