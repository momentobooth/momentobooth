import 'dart:io';

import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' hide context;
import 'package:toml/toml.dart';

part 'settings_manager.g.dart';

class SettingsManager = SettingsManagerBase with _$SettingsManager;

abstract class SettingsManagerBase with Store {

  static final SettingsManagerBase instance = SettingsManager._internal();

  static const _fileName = "Settings.toml";

  late File _settingsFile;

  @observable
  Settings? _settings;

  @computed
  Settings get settings => _settings!;

  SettingsManagerBase._internal();
  
  // Load from/Save to disk

  Future<void> load() async {
    await _ensureSettingsFileIsSet();

    if (!await _settingsFile.exists()) {
      // File does not exist, load defaults and create settings file
      _settings = Settings.withDefaults();
      await save();
      return;
    }

    // File does exist
    String settingsAsToml = await _settingsFile.readAsString();
    TomlDocument settingsDocument = TomlDocument.parse(settingsAsToml);
    Map<String, dynamic> settingsMap = settingsDocument.toMap();
    try {
      Settings.fromJson(settingsMap);
    } catch (_) {
      // FIXME: Failed to parse, load defaults and create settings file
      print("Settings parse failed, using defaults");
      _settings = Settings.withDefaults();
      await save();
      return;
    }
    print("Settings loaded from: ${_settingsFile.path}");
  }

  Future<void> save() async {
    await _ensureSettingsFileIsSet();

    Map<String, dynamic> settingsMap = _settings!.toJson();
    TomlDocument settingsDocument = TomlDocument.fromMap(settingsMap);
    String settingsAsToml = settingsDocument.toString();
    _settingsFile.writeAsString(settingsAsToml);
    print("Settings written to: ${_settingsFile.path}");
  }

  // Helpers

  Future<void> _ensureSettingsFileIsSet() async {
    // Find path
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String filePath = join(storageDirectory.path, _fileName);
    _settingsFile = File(filePath);
  }

}
