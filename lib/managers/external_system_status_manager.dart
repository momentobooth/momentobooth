import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';

class ExternalSystemStatus {
  final ExternalSystemCheckSetting check;
  final SubsystemStatus isHealthy;

  ExternalSystemStatus({
    required this.check,
    required this.isHealthy,
  });
}

class ExternalSystemStatusManager {
  @observable
  List<ExternalSystemStatus> _statuses = [];
  Timer? _checkTimer;

  ExternalSystemStatusManager();

  /// Initializes the manager, setting up the timer for periodic checks.
  void initialize() {
    if (_checkTimer != null && _checkTimer!.isActive) {
      _checkTimer!.cancel();
    }
    loadStatuses();
    _checkTimer = Timer.periodic(Duration(seconds: getIt<SettingsManager>().settings.externalSystemCheckIntervalSeconds), (timer) {
      runAllChecks();
    });
  }

  void loadStatuses() {
    _statuses = getIt<SettingsManager>().settings.externalSystemChecks.map((el) => ExternalSystemStatus(check: el, isHealthy: SubsystemStatus.initial())).toList();
  }

  /// Runs all health checks and returns their statuses
  Future<List<ExternalSystemStatus>> runAllChecks() async {
    loadStatuses();  // Fixme: we reset the isHealthy state here, which might not be ideal.
    return Future.wait(_statuses.map((status) => runCheck(status.check)));
  }

  static Future<ExternalSystemStatus> runCheck(ExternalSystemCheckSetting check) async {
    switch (check.type) {
      case ExternalSystemCheckType.ping:
        return await _pingCheck(check);
      case ExternalSystemCheckType.http:
        return await _httpCheck(check);
    }
  }

  static Future<ExternalSystemStatus> _pingCheck(ExternalSystemCheckSetting check) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'ping' : 'ping',
        Platform.isWindows ? ['-n', '1', check.address] : ['-c', '1', check.address],
      );
      final success = result.exitCode == 0;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success ? const SubsystemStatus.ok() : SubsystemStatus.error(message: "ping unsuccessful", exception: result.stdout.toString()),
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: SubsystemStatus.error(message: "ping unsuccessful", exception: e.toString()),
      );
    }
  }

  static Future<ExternalSystemStatus> _httpCheck(ExternalSystemCheckSetting check) async {
    try {
      final response = await http.get(Uri.parse(check.address)).timeout(Duration(seconds: 5));
      final success = response.statusCode >= 200 && response.statusCode < 400;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success ? const SubsystemStatus.ok() : SubsystemStatus.error(message: "http request unsuccessful", exception: 'HTTP ${response.statusCode}'),
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: SubsystemStatus.error(message:  "http request unsuccessful", exception: e.toString()),
      );
    }
  }
}
