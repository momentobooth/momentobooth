// ignore_for_file: invalid_annotation_target

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:csslib/parser.dart' as css_parser;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/exceptions/default_setting_restore_exception.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/gphoto2.dart';
import 'package:momento_booth/src/rust/models/image_operations.dart';
import 'package:momento_booth/utils/color_vision_deficiency.dart';
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
sealed class Settings with _$Settings implements TomlEncodableValue {

  const Settings._();

  const factory Settings({
    @Default({}) Set<OnboardingStep> onboardingStepsDone,
    @Default(5) int captureDelaySeconds,
    @Default(false) bool loadLastProject,
    @Default(1.5) double collageAspectRatio,
    @Default(0) double collagePadding,
    @Default(true) bool enableWakelock,
    @JsonKey(defaultValue: HardwareSettings.withDefaults) required HardwareSettings hardware,
    @JsonKey(defaultValue: OutputSettings.withDefaults) required OutputSettings output,
    @JsonKey(defaultValue: UiSettings.withDefaults) required UiSettings ui,
    @JsonKey(defaultValue: MqttIntegrationSettings.withDefaults) required MqttIntegrationSettings mqttIntegration,
    @JsonKey(defaultValue: FaceRecognitionSettings.withDefaults) required FaceRecognitionSettings faceRecognition,
    @JsonKey(defaultValue: DebugSettings.withDefaults) required DebugSettings debug,
    @Default([]) List<ExternalSystemCheckSetting> externalSystemChecks,
    @Default(60) int externalSystemCheckIntervalSeconds,
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
sealed class HardwareSettings with _$HardwareSettings implements TomlEncodableValue {

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
    @Default(false) bool gPhoto2DownloadExtraFiles,
    @Default(0) int gPhoto2AutoFocusMsBeforeCapture,
    @Default(100) int captureDelayGPhoto2,
    @Default(200) int captureDelaySony,
    @JsonKey(defaultValue: _captureLocationFromJson) required String captureLocation,
    @JsonKey(defaultValue: _captureLocationFromJson) required String serveFromDirectoryPath,
    @Default(true) bool saveCapturesToDisk,
    @Default(PrintingImplementation.flutterPrinting) PrintingImplementation printingImplementation,
    @Default([]) List<String> flutterPrintingPrinterNames,
    @Default("http://localhost:631/") String cupsUri,
    @Default(false) bool cupsIgnoreTlsErrors,
    @Default("") String cupsUsername,
    @Default("") String cupsPassword,
    @Default([]) List<String> cupsPrinterQueues,
    @JsonKey(defaultValue: PrintLayoutSettings.withDefaults) required PrintLayoutSettings printLayoutSettings,
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

@Freezed(fromJson: true, toJson: true)
sealed class PrintLayoutSettings with _$PrintLayoutSettings implements TomlEncodableValue {

  const PrintLayoutSettings._();

  const factory PrintLayoutSettings({

    @JsonKey(defaultValue: MediaSettings.withDefaults) required MediaSettings mediaSizeNormal,
    @JsonKey(defaultValue: MediaSettings.withDefaults) required MediaSettings mediaSizeSplit,
    @JsonKey(defaultValue: MediaSettings.withDefaults) required MediaSettings mediaSizeSmall,
    @JsonKey(defaultValue: GridSettings.withDefaults) required GridSettings gridSmall,
    @JsonKey(defaultValue: MediaSettings.withDefaults) required MediaSettings mediaSizeTiny,
    @JsonKey(defaultValue: GridSettings.withDefaults) required GridSettings gridTiny,
  }) = _PrintLayoutSettings;

  factory PrintLayoutSettings.withDefaults() => PrintLayoutSettings.fromJson({});

  factory PrintLayoutSettings.fromJson(Map<String, Object?> json) => _$PrintLayoutSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@Freezed(fromJson: true, toJson: true)
sealed class MediaSettings with _$MediaSettings implements TomlEncodableValue {

  const MediaSettings._();

  const factory MediaSettings({
    @Default("") String mediaSizeString,
    @Default(0.0) double mediaSizeHeight,
    @Default(0.0) double mediaSizeWidth,
  }) = _MediaSettings;

  factory MediaSettings.withDefaults() => MediaSettings.fromJson({});

  factory MediaSettings.fromJson(Map<String, Object?> json) => _$MediaSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@Freezed(fromJson: true, toJson: true)
sealed class GridSettings with _$GridSettings implements TomlEncodableValue {

  const GridSettings._();

  const factory GridSettings({
    @Default(1) int x,
    @Default(1) int y,
    @Default(false) bool rotate,
  }) = _GridSettings;

  factory GridSettings.withDefaults() => GridSettings.fromJson({});

  factory GridSettings.fromJson(Map<String, Object?> json) => _$GridSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// /////////////// //
// Output Settings //
// /////////////// //

@Freezed(fromJson: true, toJson: true)
sealed class OutputSettings with _$OutputSettings implements TomlEncodableValue {

  const OutputSettings._();

  const factory OutputSettings({
    @Default(80) int jpgQuality,
    @Default(4.0) double resolutionMultiplier,
    @Default(false) bool useFullFrame1PhotoLayout,
    @Default(ExportFormat.jpgFormat) ExportFormat exportFormat,
    @Default("https://send.vis.ee/") String firefoxSendServerUrl,
    @Default(Duration(seconds: 5)) Duration firefoxSendControlCommandTimeout,
    @Default(Duration(seconds: 15)) Duration firefoxSendTransferTimeout,
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
sealed class UiSettings with _$UiSettings implements TomlEncodableValue {

  const UiSettings._();

  const factory UiSettings({
    @Default(45) int returnToHomeTimeoutSeconds,
    @Default(Language.english) Language language,
    @Default([]) List<LottieAnimationSettings> introScreenLottieAnimations,
    @Default(true) bool showTouchIndicator,
    @Default(false) bool enableSfx,
    @Default("") String clickSfxFile,
    @Default("") String shareScreenSfxFile,
    @Default(false) bool allowScrollGestureWithMouse,
    @Default(ScreenTransitionAnimation.fadeAndScale) ScreenTransitionAnimation screenTransitionAnimation,
    @Default(BackgroundBlur.textureBlur) BackgroundBlur backgroundBlur,
    @Default(FilterQuality.low) FilterQuality screenTransitionAnimationFilterQuality,
    @Default(FilterQuality.medium) FilterQuality liveViewFilterQuality,
    @Default(false) bool showSettingsButton,
  }) = _UiSettings;

  factory UiSettings.withDefaults() => UiSettings.fromJson({});

  factory UiSettings.fromJson(Map<String, Object?> json) => _$UiSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@Freezed(fromJson: true, toJson: true)
sealed class LottieAnimationSettings with _$LottieAnimationSettings implements TomlEncodableValue {

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
sealed class MqttIntegrationSettings with _$MqttIntegrationSettings implements TomlEncodableValue {

  const MqttIntegrationSettings._();

  const factory MqttIntegrationSettings({
    @Default(false) bool enable,
    @Default("localhost") String host,
    @Default(1883) int port,
    @Default(false) bool secure,
    @Default(true) bool verifyCertificate,
    @Default(false) bool useWebSocket,
    @Default("") String username,
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

@Freezed(fromJson: true, toJson: true)
sealed class FaceRecognitionSettings with _$FaceRecognitionSettings implements TomlEncodableValue {

  const FaceRecognitionSettings._();

  const factory FaceRecognitionSettings({
    @Default(false) bool enable,
    @Default('http://localhost:3232/') String serverUrl,
  }) = _FaceRecognitionSettings;

  factory FaceRecognitionSettings.withDefaults() => FaceRecognitionSettings.fromJson({});

  factory FaceRecognitionSettings.fromJson(Map<String, Object?> json) => _$FaceRecognitionSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// ///////////////////// //
// External System Check //
// ///////////////////// //

@Freezed(fromJson: true, toJson: true)
sealed class ExternalSystemCheckSetting with _$ExternalSystemCheckSetting implements TomlEncodableValue {

  const ExternalSystemCheckSetting._();

  const factory ExternalSystemCheckSetting({
    required String name,
    required String address,
    required ExternalSystemCheckType type,
    @Default(ExternalSystemCheckSeverity.warning) ExternalSystemCheckSeverity severity,
    @Default(true) bool enabled,
  }) = _ExternalSystemCheckSetting;

  factory ExternalSystemCheckSetting.withDefaults() => ExternalSystemCheckSetting.fromJson({});

  factory ExternalSystemCheckSetting.fromJson(Map<String, Object?> json) => _$ExternalSystemCheckSettingFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// ////////////// //
// Debug Settings //
// ////////////// //

@Freezed(fromJson: true, toJson: true)
sealed class DebugSettings with _$DebugSettings implements TomlEncodableValue {

  const DebugSettings._();

  const factory DebugSettings({
    @Default(false) bool showFpsCounter,
    @Default(ColorVisionDeficiency.none) ColorVisionDeficiency simulateCvd,
    @Default(9) int simulateCvdSeverity,
    @Default(false) bool enableExtensivePrintJobLog,
    @Default(false) bool enableVideoMode,
    @Default(10) int videoDuration,
    @Default(2500) int videoPreRecordDelayMs,
    @Default(0) int videoPostRecordDelayMs,
    @Default("") String ffmpegArgumentsForRecording,
    @Default("Summarize the following transcript in one sentence:") String textSummaryPrompt,
    @Default("gpt-4o-mini") String llmModel,
  }) = _DebugSettings;

  factory DebugSettings.withDefaults() => DebugSettings.fromJson({});

  factory DebugSettings.fromJson(Map<String, Object?> json) => _$DebugSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

// /////////////// //
// Default helpers //
// /////////////// //

String _captureLocationFromJson() => join(_getHome(), "Pictures", "MomentoBooth", "Captures");
String _clientIdFromJson() => 'momentobooth-photobooth-${getRandomString()}';
String _homeAssistantComponentIdFromJson() => 'momentobooth-${getRandomString()}';

// ////////// //
// Converters //
// ////////// //

class ColorColorCodeConverter implements JsonConverter<Color, String> {

  const ColorColorCodeConverter();

  @override
  Color fromJson(String colorCode) {
    return Color(css_parser.Color.hex('FF${colorCode.substring(1)}').argbValue);
  }

  @override
  String toJson(Color color) {
    String r = (color.r * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    String g = (color.g * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    String b = (color.b * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }

}
