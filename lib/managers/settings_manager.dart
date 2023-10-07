import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:toml/toml.dart';

part 'settings_manager.g.dart';

class SettingsManager extends _SettingsManagerBase with _$SettingsManager {

  static final SettingsManager instance = SettingsManager._internal();

  SettingsManager._internal();

}

abstract class _SettingsManagerBase with Store, UiLoggy {

  static const _fileName = "MomentoBooth_Settings.toml";

  late File _settingsFile;

  @observable
  Settings? _settings;

  @computed
  Settings get settings => _settings!;

  // ////// //
  // Mutate //
  // ////// //

  @action
  Future<void> updateAndSave(Settings settings) async {
    if (settings == _settings) return;
    _settings = settings;
    await _save();
  }
  
  // /////////// //
  // Persistence //
  // /////////// //

  @action
  Future<void> load() async {
    loggy.debug("Loading settings");
    await _ensureSettingsFileIsSet();

    if (!_settingsFile.existsSync()) {
      // File does not exist, load defaults and create settings file
      _settings = Settings.withDefaults();
      await _save();
      return;
    }

    // File does exist
    String settingsAsToml = await _settingsFile.readAsString();
    TomlDocument settingsDocument = TomlDocument.parse(settingsAsToml);
    Map<String, dynamic> settingsMap = settingsDocument.toMap();
    try {
      _settings = Settings.fromJson(settingsMap);
      loggy.debug("Loaded settings: ${_settings?.toJson().toString() ?? "null"}");
    } catch (_) {
      // Fixme: Failed to parse, load defaults and create settings file
      _settings = Settings.withDefaults();
    }
    await _save();
  }

  Future<void> _save() async {
    loggy.debug("Saving settings");
    await _ensureSettingsFileIsSet();

    Map<String, dynamic> settingsMap = _settings!.toJson();
    TomlDocument settingsDocument = TomlDocument.fromMap(settingsMap);
    String settingsAsToml = settingsDocument.toString();
    await _settingsFile.writeAsString(settingsAsToml);

    loggy.debug("Saved settings");
  }

  // /////// //
  // Helpers //
  // /////// //

  Future<void> _ensureSettingsFileIsSet() async {
    // Find path
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String filePath = join(storageDirectory.path, _fileName);
    _settingsFile = File(filePath);
  }

}
