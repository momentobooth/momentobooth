import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';

part 'settings_manager.g.dart';

class SettingsManager = SettingsManagerBase with _$SettingsManager;

abstract class SettingsManagerBase with Store, Logger, Subsystem {

  // Loading the settings with default values to prevent errors from use before initialization.
  // This is fine as the initialize method overwrites the value anyway.
  @readonly
  Settings _settings = Settings.withDefaults();

  @override
  Future<void> initialize() async {
    try {
      SerialiableRepository<Settings> settingsRepository = getIt<SerialiableRepository<Settings>>();
      bool hasExistingSettings = await settingsRepository.hasExistingData();

      if (!hasExistingSettings) {
        reportSubsystemOk(message: "No existing settings data found, a new file will be created.");
      } else {
        _settings = await settingsRepository.get();
        reportSubsystemOk();
      }
    } catch (e) {
      reportSubsystemError(
        message: "Could not read existing settings. Open the details view for details and solutions.",
        exception: e.toString(),
        actions: {
          'Accept default settings': unblockSavingAndSave,
          'Retry': initialize,
        }
      );
      _blockSaving = true;
    }
  }

  // /////////// //
  // Persistence //
  // /////////// //

  @readonly
  bool _blockSaving = false;

  Future<void> unblockSavingAndSave() async {
    _blockSaving = false;
    logInfo("Unblocked saving of settings, now saving settings");
    await getIt<SerialiableRepository<Settings>>().write(_settings);
    logDebug("Saved settings");
    reportSubsystemOk(message: "Default settings accepted.");
  }

  @action
  Future<void> updateAndSave(Settings settings) async {
    if (settings == _settings) return;

    if (!_blockSaving) {
      logDebug("Saving settings");
      await getIt<SerialiableRepository<Settings>>().write(settings);
      logDebug("Saved settings");
    } else {
      logDebug("Saving blocked");
    }

    _settings = settings;
    getIt<MqttManager>().publishSettings(settings);
  }

}
