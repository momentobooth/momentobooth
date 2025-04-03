import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';

part 'settings_manager.g.dart';

class SettingsManager = SettingsManagerBase with _$SettingsManager;

abstract class SettingsManagerBase extends Subsystem with Store, Logger {

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
        await updateAndSave(Settings.withDefaults());
        if (subsystemStatus is SubsystemStatusOk) reportSubsystemOk(message: "No existing settings data found, a new file is created.");
      } else {
        _settings = await settingsRepository.get();
        _blockSaving = false;
        reportSubsystemOk();
      }
    } catch (e, s) {
      String message = 'Could not read existing settings';
      logError(message, e, s);
      reportSubsystemError(
        message: "Could not read existing settings. Open the details view for details and solutions.",
        exception: e.toString(),
        actions: {'Accept default settings': unblockSavingAndSave, 'Retry': initialize},
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
    await updateAndSave(Settings.withDefaults());
    if (subsystemStatus is SubsystemStatusOk) reportSubsystemOk(message: "Default settings accepted.");
  }

  @action
  Future<void> updateAndSave(Settings settings) async {
    if (!_blockSaving) {
      logDebug("Saving settings");
      try {
        await getIt<SerialiableRepository<Settings>>().write(settings);
        logDebug("Saved settings");
        reportSubsystemOk();
      } catch (e, s) {
        String message = 'Failed to save settings';
        logError(message, e, s);
        reportSubsystemError(
          message: message,
          exception: e.toString(),
          actions: {'Try again': () => updateAndSave(_settings)},
        );
      }
    } else {
      logWarning("Saving blocked");
    }

    _settings = settings;
    getIt<MqttManager>().publishSettings(settings);
  }

}
