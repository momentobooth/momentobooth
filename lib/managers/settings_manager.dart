import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/repositories/serializable/toml_backup_repository.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/logger.dart';

part 'settings_manager.g.dart';

class SettingsManager = SettingsManagerBase with _$SettingsManager;

abstract class SettingsManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Application settings";

  // Loading the settings with default values to prevent errors from use before initialization.
  // This is fine as the initialize method overwrites the value anyway.
  @readonly
  Settings _settings = Settings.withDefaults();

  @override
  Future<void> initialize() async {
    StartupBackupResult? backup;
    try {
      SerialiableRepository<Settings> settingsRepository = getIt<SerialiableRepository<Settings>>();
      bool hasExistingSettings = await settingsRepository.hasExistingData();

      if (!hasExistingSettings) {
        await save();
        if (subsystemStatus is SubsystemStatusOk) reportSubsystemOk(message: "No existing settings data found, a new file is created.");
      } else {
        backup = await _backUpOnStartup();
        _settings = await settingsRepository.get();
        _blockSaving = false;
        // Store the settings in the format of this version, so the same backup is not made again on the next start.
        if (backup?.backup != null) await save();
        reportSubsystemOk(message: _unsupportedSettingsMessage(backup));
      }
    } catch (e, s) {
      String message = 'Could not read existing settings';
      logError(message, e, s);
      String backupNote = backup?.backup != null ? " A backup of the file has been made, see the Import & backups page." : "";
      reportSubsystemError(
        message: "Could not read existing settings.$backupNote Open the details view for details and solutions.",
        exception: e.toString(),
        actions: {'Accept current settings': unblockSavingAndSave, 'Retry': initialize},
      );
      _blockSaving = true;
    }
  }

  /// Backs up the settings file before it is loaded when needed, see [TomlBackupRepository.backUpOnStartup]. A failing
  /// backup does not stop the startup, and returns null.
  Future<StartupBackupResult?> _backUpOnStartup() async {
    try {
      return await getIt<TomlBackupRepository<Settings>>().backUpOnStartup(appVersion: appVersionWithBuild);
    } catch (e, s) {
      logError("Could not back up the settings", e, s);
      return null;
    }
  }

  String? _unsupportedSettingsMessage(StartupBackupResult? backup) {
    if (backup == null || backup.backup == null || backup.unsupportedPaths.isEmpty) return null;

    logWarning("Removed settings not used by this version: ${backup.unsupportedPaths.join(', ')}");
    return "${backup.unsupportedPaths.length} settings were not used by this version and have been removed. "
        "A backup has been made, see the Import & backups page.";
  }

  // /////////// //
  // Persistence //
  // /////////// //

  @readonly
  bool _blockSaving = false;

  Future<void> unblockSavingAndSave() async {
    _blockSaving = false;
    logInfo("Unblocked saving of settings, now saving settings");
    await save();
    if (subsystemStatus is SubsystemStatusOk) reportSubsystemOk(message: "Default settings accepted.");
  }

  @action
  Future<void> save() async {
    if (_blockSaving) {
      logWarning("Saving blocked");
      return;
    }

    logDebug("Saving settings");
    try {
      await getIt<SerialiableRepository<Settings>>().write(_settings);
      logDebug("Saved settings");
      reportSubsystemOk();
    } catch (e, s) {
      String message = 'Failed to save settings';
      logError(message, e, s);
      reportSubsystemError(
        message: message,
        exception: e.toString(),
        actions: {'Try again': save},
      );
    }
  }

  @action
  Future<void> updateAndSave(Settings settings) async {
    if (settings == _settings) return;

    _settings = settings;
    await save();

    getIt<MqttManager>().publishSettings(settings);
  }

  @action
  Future<void> mutateAndSave(Settings Function(Settings settings) settings) async {
    await updateAndSave(settings(_settings));
  }

}
