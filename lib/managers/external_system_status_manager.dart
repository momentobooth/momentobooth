import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:momento_booth/models/settings.dart';

/// Represents a single external system check (ping or HTTP)
class ExternalSystemCheck {
  final String name;
  final String address; // IP/hostname or URL
  final ExternalSystemCheckType type;

  ExternalSystemCheck({
    required this.name,
    required this.address,
    required this.type,
  });
}

class ExternalSystemStatus {
  final ExternalSystemCheck check;
  final bool isHealthy;
  final String? error;

  ExternalSystemStatus({
    required this.check,
    required this.isHealthy,
    this.error,
  });
}

class ExternalSystemStatusManager {
  final List<ExternalSystemCheck> checks;

  ExternalSystemStatusManager(this.checks);

  /// Runs all health checks and returns their statuses
  Future<List<ExternalSystemStatus>> runAllChecks() async {
    return Future.wait(checks.map(_runCheck));
  }

  Future<ExternalSystemStatus> _runCheck(ExternalSystemCheck check) async {
    switch (check.type) {
      case ExternalSystemCheckType.ping:
        return await _pingCheck(check);
      case ExternalSystemCheckType.http:
        return await _httpCheck(check);
    }
  }

  Future<ExternalSystemStatus> _pingCheck(ExternalSystemCheck check) async {
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

  Future<ExternalSystemStatus> _httpCheck(ExternalSystemCheck check) async {
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
