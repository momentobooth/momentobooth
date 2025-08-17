import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';

class ExternalSystemStatus {
  final ExternalSystemCheckSetting check;
  final bool isHealthy;
  final String? error;

  ExternalSystemStatus({
    required this.check,
    required this.isHealthy,
    this.error,
  });
}

class ExternalSystemStatusManager {
  late final List<ExternalSystemCheckSetting> checks;
  Timer? _checkTimer;

  ExternalSystemStatusManager({List<ExternalSystemCheckSetting>? checks}) {
    if (checks != null) {
      this.checks = checks;
      return;
    }
    this.checks = getIt<SettingsManager>().settings.externalSystemChecks;
  }

  /// Initializes the manager, setting up the timer for periodic checks.
  void initialize() {
    if (_checkTimer != null && _checkTimer!.isActive) {
      _checkTimer!.cancel();
    }
    _checkTimer = Timer.periodic(Duration(seconds: getIt<SettingsManager>().settings.externalSystemCheckIntervalSeconds), (timer) {
      runAllChecks();
    });
  }

  /// Runs all health checks and returns their statuses
  Future<List<ExternalSystemStatus>> runAllChecks() async {
    return Future.wait(checks.map(_runCheck));
  }

  Future<ExternalSystemStatus> _runCheck(ExternalSystemCheckSetting check) async {
    switch (check.type) {
      case ExternalSystemCheckType.ping:
        return await _pingCheck(check);
      case ExternalSystemCheckType.http:
        return await _httpCheck(check);
    }
  }

  Future<ExternalSystemStatus> _pingCheck(ExternalSystemCheckSetting check) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'ping' : 'ping',
        Platform.isWindows ? ['-n', '1', check.address] : ['-c', '1', check.address],
      );
      final success = result.exitCode == 0;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success,
        error: success ? null : result.stderr.toString(),
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: false,
        error: e.toString(),
      );
    }
  }

  Future<ExternalSystemStatus> _httpCheck(ExternalSystemCheckSetting check) async {
    try {
      final response = await http.get(Uri.parse(check.address)).timeout(Duration(seconds: 5));
      final success = response.statusCode >= 200 && response.statusCode < 400;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success,
        error: success ? null : 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: false,
        error: e.toString(),
      );
    }
  }
}
