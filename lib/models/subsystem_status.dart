import 'package:freezed_annotation/freezed_annotation.dart';

part 'subsystem_status.freezed.dart';

@freezed
class SubsystemStatus with _$SubsystemStatus {

  const SubsystemStatus._();

  const factory SubsystemStatus.busy({
    required String message,
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusBusy;

  const factory SubsystemStatus.ok({
    String? message,
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusOk;

  const factory SubsystemStatus.disabled({
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusDisabled;

  const factory SubsystemStatus.warning({
    required String message,
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusWarning;

  const factory SubsystemStatus.error({
    required String message,
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusError;

  const factory SubsystemStatus.deferred({
    required List<SubsystemStatus> children,
    @Default({}) Map<String, Future Function()> actions,
  }) = SubsystemStatusWithChildren;

}
