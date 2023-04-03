import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toml/toml.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings implements TomlEncodableValue {
  const Settings._();

  const factory Settings({
    required int captureDelaySeconds,
    required HardwareSettings hardware,
  }) = _Settings;

  factory Settings.withDefaults() => Settings(
        captureDelaySeconds: 5,
        hardware: HardwareSettings.withDefaults(),
      );

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@freezed
class HardwareSettings with _$HardwareSettings implements TomlEncodableValue {
  const HardwareSettings._();

  const factory HardwareSettings({
    required LiveViewMethod liveViewMethod,
    required CaptureMethod captureMethod,
  }) = _HardwareSettings;

  factory HardwareSettings.withDefaults() => HardwareSettings(
        liveViewMethod: LiveViewMethod.fakeImage,
        captureMethod: CaptureMethod.liveViewSource,
      );

  factory HardwareSettings.fromJson(Map<String, Object?> json) => _$HardwareSettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// Enums

enum LiveViewMethod {
  fakeImage(0),
  webcam(1);

  // can add more properties or getters/methods if needed
  final int value;

  // can use named parameters if you want
  const LiveViewMethod(this.value);
}

enum CaptureMethod {
  liveViewSource(0),
  sonyImagingEdgeDesktop(1);

  // can add more properties or getters/methods if needed
  final int value;

  // can use named parameters if you want
  const CaptureMethod(this.value);
}
