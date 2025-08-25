import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';

part 'external_system_status.freezed.dart';

@freezed
class ExternalSystemStatus with _$ExternalSystemStatus {
  @override
  final ExternalSystemCheckSetting check;
  @override
  final SubsystemStatus isHealthy;
  @override
  final DateTime timestamp;
  @override
  final bool inProgress;

  ExternalSystemStatus({
    required this.check,
    required this.isHealthy,
    this.inProgress = false,
  }): timestamp = DateTime.now();
}
