import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'wakelock_manager.g.dart';

class WakelockManager = WakelockManagerBase with _$WakelockManager;

abstract class WakelockManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Wakelock manager";

  final Lock _updateWakelockStateLock = Lock();

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Future<void> initialize() async {
    autorun((_) {
      bool enableWakelock = getIt<SettingsManager>().settings.enableWakelock;
      _toggleWakelock(enableWakelock);
    });
  }

  void _toggleWakelock(bool enable) {
    _updateWakelockStateLock.synchronized(() async {
      try {
        reportSubsystemBusy(message: '${enable ? 'Enabling' : 'Disabling'} wakelock');
        await WakelockPlus.toggle(enable: enable);
        reportSubsystemOk(message: 'Wakelock ${enable ? 'enabled' : 'disabled'}');
      } catch (e) {
        reportSubsystemError(message: 'Could not ${enable ? 'enable' : 'disable'} wakelock', exception: e.toString());
      }
    });
  }

}
