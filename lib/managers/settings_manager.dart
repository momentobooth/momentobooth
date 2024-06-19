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

abstract class SettingsManagerBase with Store, Logger, Subsystem {

  @readonly
  late Settings _settings;

  @override
  Future<SubsystemStatus> initialize() async {
    try {
      SerialiableRepository<Settings> settingsRepository = getIt<SerialiableRepository<Settings>>();
      bool hasExistingSettings = await settingsRepository.hasExistingData();

      if (!hasExistingSettings) {
        _settings = Settings.withDefaults();
        return const SubsystemStatus.ok(
          message: "No existing settings found, a new settings file has been created.",
        );
      } else {
        _settings = await settingsRepository.get();
        return const SubsystemStatus.ok();
      }
    } catch (e) {
      _settings = Settings.withDefaults();
      return SubsystemStatus.warning(
        message: "Could not read existing settings: $e\n\nDefault settings have been loaded. Your current settings file will be overwritten if you alter any settings. Backup your current settings file in case you need anything from it.",
      );
    }
  }

  // /////////// //
  // Persistence //
  // /////////// //

  @action
  Future<void> updateAndSave(Settings settings) async {
    if (settings == _settings) return;

    logDebug("Saving settings");
    await getIt<SerialiableRepository<Settings>>().write(settings);
    logDebug("Saved settings");

    _settings = settings;
    getIt<MqttManager>().publishSettings(settings);
  }

}
