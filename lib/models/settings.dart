// ignore_for_file: invalid_annotation_target

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/exceptions/default_setting_restore_exception.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/utils/random_string.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

part 'settings.enums.dart';
part 'settings.freezed.dart';
part 'settings.g.dart';

// ///////////// //
// Root settings //
// ///////////// //

@Freezed(fromJson: true, toJson: true)
class Settings with _$Settings implements TomlEncodableValue {
  
  const Settings._();

  const factory Settings({
    @Default(5) int captureDelaySeconds,
    @Default(1.5) double collageAspectRatio,
    @Default(0) double collagePadding,
    @Default(true) bool singlePhotoIsCollage,
    @JsonKey(defaultValue: _templatesFolderFromJson) required String templatesFolder,
    @JsonKey(defaultValue: HardwareSettings.withDefaults) required HardwareSettings hardware,
    @JsonKey(defaultValue: OutputSettings.withDefaults) required OutputSettings output,
    @JsonKey(defaultValue: UiSettings.withDefaults) required UiSettings ui,
    @JsonKey(defaultValue: MqttIntegrationSettings.withDefaults) required MqttIntegrationSettings mqttIntegration,
    @JsonKey(defaultValue: DebugSettings.withDefaults) required DebugSettings debug,
  }) = _Settings;

  factory Settings.withDefaults() => Settings.fromJson({});

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// ///////////////// //
// Hardware Settings //
// ///////////////// //

@Freezed(fromJson: true, toJson: true)
class HardwareSettings with _$HardwareSettings implements TomlEncodableValue {

  const HardwareSettings._();

  const factory HardwareSettings({
    @Default(Rotate.none) Rotate liveViewAndCaptureRotate,
    @Default(Flip.horizontally) Flip liveViewFlip,
    @Default(1.5) double liveViewAndCaptureAspectRatio,
    @Default(Flip.none) Flip captureFlip,
    @Default(LiveViewMethod.webcam) LiveViewMethod liveViewMethod,
    @Default("") String liveViewWebcamId,
    @Default(CaptureMethod.liveViewSource) CaptureMethod captureMethod,
    @Default("") String gPhoto2CameraId,
    @Default(GPhoto2SpecialHandling.none) GPhoto2SpecialHandling gPhoto2SpecialHandling,
    @Default("") String gPhoto2CaptureTarget,
    @Default(100) int captureDelayGPhoto2,
    @Default(200) int captureDelaySony,
    @JsonKey(defaultValue: _captureLocationFromJson) required String captureLocation,
    @Default(true) bool saveCapturesToDisk,
    @JsonKey(defaultValue: _captureStorageLocationFromJson) required String captureStorageLocation,
    @Default([]) List<String> printerNames,
    @Default(148) double pageHeight,
    @Default(100) double pageWidth,
    @Default(true) bool usePrinterSettings,
    @Default(0) double printerMarginTop,
    @Default(0) double printerMarginRight,
    @Default(0) double printerMarginBottom,
    @Default(0) double printerMarginLeft,
    @Default(4) int printerQueueWarningThreshold,
  }) = _HardwareSettings;

  factory HardwareSettings.withDefaults() => HardwareSettings.fromJson({});

  factory HardwareSettings.fromJson(Map<String, Object?> json) => _$HardwareSettingsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// /////////////// //
// Output Settings //
// /////////////// //

@Freezed(fromJson: true, toJson: true)
class OutputSettings with _$OutputSettings implements TomlEncodableValue {

  const OutputSettings._();

  const factory OutputSettings({
    @JsonKey(defaultValue: _localFolderFromJson) required String localFolder,
    @Default(80) int jpgQuality,
    @Default(4.0) double resolutionMultiplier,
    @Default(ExportFormat.jpgFormat) ExportFormat exportFormat,
    @Default("https://send.vis.ee/") String firefoxSendServerUrl,
  }) = _OutputSettings;

  factory OutputSettings.withDefaults() => OutputSettings.fromJson({});

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
  throw DefaultSettingRestoreException('Could not find the user\'s home folder: Platform unsupported');
}

// /////////// //
// UI Settings //
// /////////// //

@Freezed(fromJson: true, toJson: true)
class UiSettings with _$UiSettings implements TomlEncodableValue {

  const UiSettings._();

  const factory UiSettings({
    @Default(Language.english) Language language,
    @Default([]) List<LottieAnimationSettings> introScreenLottieAnimations,
    @Default(true) bool displayConfetti,
    @Default(false) bool enableSfx,
    @Default("") String clickSfxFile,
    @Default("") String shareScreenSfxFile,
    @Default(ScreenTransitionAnimation.fadeAndScale) ScreenTransitionAnimation screenTransitionAnimation,
    @Default(BackgroundBlur.textureBlur) BackgroundBlur backgroundBlur,
    @Default(FilterQuality.low) FilterQuality screenTransitionAnimationFilterQuality,
    @Default(FilterQuality.medium) FilterQuality liveViewFilterQuality,
  }) = _UiSettings;

  factory UiSettings.withDefaults() => UiSettings.fromJson({});

  factory UiSettings.fromJson(Map<String, Object?> json) => _$UiSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@Freezed(fromJson: true, toJson: true)
class LottieAnimationSettings with _$LottieAnimationSettings implements TomlEncodableValue {

  const LottieAnimationSettings._();

  const factory LottieAnimationSettings({
    @Default("") String file,
    @Default(0) double width,
    @Default(0) double height,
    @Default(AnimationAnchor.screen) AnimationAnchor anchor,
    @Default(0) double alignmentX,
    @Default(0) double alignmentY,
    @Default(0) double offsetDx,
    @Default(0) double offsetDy,
    @Default(0) double rotation,
  }) = _LottieAnimationSettings;

  factory LottieAnimationSettings.fromJson(Map<String, Object?> json) => _$LottieAnimationSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// //////////////////// //
// Integration Settings //
// //////////////////// //

@Freezed(fromJson: true, toJson: true)
class MqttIntegrationSettings with _$MqttIntegrationSettings implements TomlEncodableValue {

  const MqttIntegrationSettings._();

  const factory MqttIntegrationSettings({
    @Default(false) bool enable,
    @Default("localhost") String host,
    @Default(1883) int port,
    @Default(false) bool secure,
    @Default(true) bool verifyCertificate,
    @Default(false) bool useWebSocket,
    @Default("") String username,
    @Default("") String password,
    @JsonKey(defaultValue: _clientIdFromJson) required String clientId,
    @Default("momentobooth") String rootTopic,
    @Default(false) bool enableHomeAssistantDiscovery,
    @Default("homeassistant") String homeAssistantDiscoveryTopicPrefix,
    @JsonKey(defaultValue: _homeAssistantComponentIdFromJson) required String homeAssistantComponentId,
  }) = _MqttIntegrationSettings;

  factory MqttIntegrationSettings.withDefaults() => MqttIntegrationSettings.fromJson({});

  factory MqttIntegrationSettings.fromJson(Map<String, Object?> json) => _$MqttIntegrationSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// ////////////// //
// Debug Settings //
// ////////////// //

@Freezed(fromJson: true, toJson: true)
class DebugSettings with _$DebugSettings implements TomlEncodableValue {

  const DebugSettings._();

  const factory DebugSettings({
    @Default(false) bool showFpsCounter,
  }) = _DebugSettings;

  factory DebugSettings.withDefaults() => DebugSettings.fromJson({});

  factory DebugSettings.fromJson(Map<String, Object?> json) => _$DebugSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// /////////////// //
// Default helpers //
// /////////////// //

String _templatesFolderFromJson() => join(_getHome(), "Pictures", "MomentoBooth", "Templates");
String _captureLocationFromJson() => join(_getHome(), "Pictures", "MomentoBooth", "Captures");
String _captureStorageLocationFromJson() => join(_getHome(), "Pictures", "MomentoBooth", "From camera");
String _localFolderFromJson() => join(_getHome(), "Pictures", "MomentoBooth", "Output");
String _clientIdFromJson() => 'momentobooth-photobooth-${getRandomString()}';
String _homeAssistantComponentIdFromJson() => 'momentobooth-${getRandomString()}';
