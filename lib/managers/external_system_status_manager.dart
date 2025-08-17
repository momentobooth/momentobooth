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
    logDebug("Initializing ExternalSystemStatusManager");
    if (_checkTimer != null && _checkTimer!.isActive) {
      _checkTimer!.cancel();
    }
    loadChecksFromSettings();
    _checkTimer = Timer.periodic(Duration(seconds: getIt<SettingsManager>().settings.externalSystemCheckIntervalSeconds), (timer) {
      runAllChecks();
    });
  }

  void loadChecksFromSettings() {
    systems = ObservableList.of(getIt<SettingsManager>().settings.externalSystemChecks.map((el) => ExternalSystemStatus(check: el, isHealthy: el.enabled ? SubsystemStatus.initial() :SubsystemStatus.disabled())).toList());
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
