import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';
part 'settings.enums.dart';

// ///////////// //
// Root settings //
// ///////////// //

@freezed
class Settings with _$Settings implements TomlEncodableValue {
  
  const Settings._();

  const factory Settings({
    required int captureDelaySeconds,
    required HardwareSettings hardware,
    required OutputSettings output,
  }) = _Settings;

  factory Settings.withDefaults() {
    return Settings(
      captureDelaySeconds: 5,
      hardware: HardwareSettings.withDefaults(),
      output: OutputSettings.withDefaults(),
    );
  }

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// ///////////////// //
// Hardware Settings //
// ///////////////// //

@freezed
class HardwareSettings with _$HardwareSettings implements TomlEncodableValue {

  const HardwareSettings._();

  const factory HardwareSettings({
    required LiveViewMethod liveViewMethod,
    required CaptureMethod captureMethod,
    required String captureLocation,
    required String printerName,
  }) = _HardwareSettings;

  factory HardwareSettings.withDefaults() {
    return HardwareSettings(
      liveViewMethod: LiveViewMethod.fakeImage,
      captureMethod: CaptureMethod.liveViewSource,
      captureLocation: _getHome(),
      printerName: "",
    );
  }

  factory HardwareSettings.fromJson(Map<String, Object?> json) => _$HardwareSettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// /////////////// //
// Output Settings //
// /////////////// //

@freezed
class OutputSettings with _$OutputSettings implements TomlEncodableValue {

  const OutputSettings._();

  const factory OutputSettings({
    required String localFolder,
    required String firefoxSendServerUrl,
  }) = _OutputSettings;

  factory OutputSettings.withDefaults() {
    return OutputSettings(
      localFolder: join(_getHome(), "Pictures"),
      firefoxSendServerUrl: "https://send.vis.ee/",
    );
  }

  factory OutputSettings.fromJson(Map<String, Object?> json) => _$OutputSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

String _getHome() {
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS || Platform.isLinux) {
    return envVars['HOME']!;
  } else if (Platform.isWindows) {
    return envVars['UserProfile']!;
  }
  throw 'Could not find the user\'s home folder: Platform unsupported';
}
