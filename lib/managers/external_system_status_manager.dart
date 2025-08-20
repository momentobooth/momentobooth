import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/external_system_status.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/logger.dart';

export 'package:momento_booth/models/external_system_status.dart';

part 'external_system_status_manager.g.dart';

class ExternalSystemStatusManager = ExternalSystemStatusManagerBase with _$ExternalSystemStatusManager;

abstract class ExternalSystemStatusManagerBase with Store, Logger {
  @observable
  ObservableList<ExternalSystemStatus> systems = ObservableList<ExternalSystemStatus>();
  Timer? _checkTimer;

  ObservableList<SubsystemStatus> get systemStatuses => ObservableList<SubsystemStatus>.of(systems.map((status) => status.isHealthy));

  ExternalSystemStatusManagerBase();

  /// Initializes the manager, setting up the timer for periodic checks.
  void initialize() {
    // Respond to settings changes
    autorun((_) {
      logDebug("Initializing ExternalSystemStatusManager");
      int newinterval = getIt<SettingsManager>().settings.externalSystemCheckIntervalSeconds;
      if (_checkTimer != null && _checkTimer!.isActive) {
        _checkTimer!.cancel();
      }
      
      systems = ObservableList.of(
        getIt<SettingsManager>().settings.externalSystemChecks
          .map((el) => ExternalSystemStatus(check: el, isHealthy: el.enabled ? SubsystemStatus.initial() :SubsystemStatus.disabled()))
          .toList()
      );

      _checkTimer = Timer.periodic(Duration(seconds: newinterval), (timer) {
        runAllChecks();
      });
    });
  }

  /// Runs all health checks and returns their statuses
  @action
  Future<List<ExternalSystemStatus>> runAllChecks() async {
    logDebug("Running all enabled external system checks");
    return Future.wait(systems.where((status) => status.check.enabled).map((status) => runCheck(status.check)));
  }

  @action
  Future<ExternalSystemStatus> runCheck(ExternalSystemCheckSetting check) async {
    final index = systems.indexWhere((el) => el.check == check);
    if (index != -1) {
      // Changing the status to busy while the check is running is fun, but it would intermittently seem that there is no issue, even if it was not resolved.
      systems[index] = systems[index].copyWith(inProgress: true);
    }
    final result = await switch (check.type) {
      ExternalSystemCheckType.ping => _pingCheck(check),
      ExternalSystemCheckType.http => _httpCheck(check)
    };
    if (index != -1) {
      systems[index] = result;
    }
    return result;
  }

  static SubsystemStatus _statusProducer(ExternalSystemCheckSetting check, String message, String exception) {
    return switch (check.severity) {
      ExternalSystemCheckSeverity.error => SubsystemStatus.error(message: message, exception: exception),
      ExternalSystemCheckSeverity.warning => SubsystemStatus.warning(message: message, exception: exception),
      // For info severity, we can use warning as well, since there is no negative "info" state.
      ExternalSystemCheckSeverity.info => SubsystemStatus.warning(message: message, exception: exception),
    };
  }

  static Future<ExternalSystemStatus> _pingCheck(ExternalSystemCheckSetting check) async {
    const eMessage = "ping unsuccessful";
    try {
      final result = await Process.run('ping',
        Platform.isWindows ? ['-n', '1', check.address] : ['-c', '1', check.address],
      );
      final success = result.exitCode == 0;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success ? const SubsystemStatus.ok() : _statusProducer(check, eMessage, result.stdout.toString()),
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: _statusProducer(check, eMessage, e.toString()),
      );
    }
  }

  static Future<ExternalSystemStatus> _httpCheck(ExternalSystemCheckSetting check) async {
    const eMessage = "http request unsuccessful";
    try {
      final response = await http.get(Uri.parse(check.address)).timeout(Duration(seconds: 5));
      final success = response.statusCode >= 200 && response.statusCode < 400;
      return ExternalSystemStatus(
        check: check,
        isHealthy: success ? const SubsystemStatus.ok() : _statusProducer(check, eMessage, 'HTTP ${response.statusCode}'),
      );
    } catch (e) {
      return ExternalSystemStatus(
        check: check,
        isHealthy: _statusProducer(check, eMessage, e.toString()),
      );
    }
  }
}
