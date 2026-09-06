import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';

part 'external_system_status.freezed.dart';

@freezed
class ExternalSystemStatus with _$ExternalSystemStatus {
  final ExternalSystemCheckSetting check;
  final SubsystemStatus isHealthy;
  final DateTime timestamp;
  final bool inProgress;

  ExternalSystemStatus({
    required this.check,
    required this.isHealthy,
    this.inProgress = false,
  }): timestamp = DateTime.now();
}
