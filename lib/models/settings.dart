import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';
import 'dart:ui' as ui;

part 'settings.freezed.dart';
part 'settings.g.dart';
part 'settings.enums.dart';

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
    @Default("") String templatesFolder,
    @Default(HardwareSettings()) HardwareSettings hardware,
    @Default(OutputSettings()) OutputSettings output,
    @Default(UiSettings()) UiSettings ui,
    //@Default(DebugSettings()) DebugSettings debug,
  }) = _Settings;

  factory Settings.withDefaults() => Settings.fromJson({});

  factory Settings.fromJson(Map<String, Object?> json) {
    // Default settings
    if (!json.containsKey("templatesFolder")) {
      json["templatesFolder"] = _getHome();
    }
    if (!json.containsKey("hardware")) {
      json["hardware"] = HardwareSettings.withDefaults().toJson();
    }
    if (!json.containsKey("output")) {
      json["output"] = OutputSettings.withDefaults().toJson();
    }
    // if (!json.containsKey("debug")) {
    //   json["debug"] = DebugSettings.withDefaults().toJson();
    // }

    return _$SettingsFromJson(json);
  }
  
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
    @Default(LiveViewMethod.webcam) LiveViewMethod liveViewMethod,
    @Default("") String liveViewWebcamId,
    @Default(Flip.horizontally) Flip liveViewFlipImage,
    @Default(CaptureMethod.liveViewSource) CaptureMethod captureMethod,
    @Default(200) int captureDelaySony,
    @Default("") String captureLocation,
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

  factory HardwareSettings.fromJson(Map<String, Object?> json) {
    // Default settings
    if (!json.containsKey("captureLocation")) {
      json["captureLocation"] = _getHome();
    }

    return _$HardwareSettingsFromJson(json);
  }
  
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
    @Default("") String localFolder,
    @Default(80)  int jpgQuality,
    @Default(4.0)  double resolutionMultiplier,
    @Default(ExportFormat.jpgFormat)  ExportFormat exportFormat,
    @Default("https://send.vis.ee/")  String firefoxSendServerUrl,
  }) = _OutputSettings;

  factory OutputSettings.withDefaults() => OutputSettings.fromJson({});

  factory OutputSettings.fromJson(Map<String, Object?> json) {
    // Default settings
    if (!json.containsKey("localFolder")) {
      json["localFolder"] = join(_getHome(), "Pictures");
    }

    return _$OutputSettingsFromJson(json);
  }

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

// /////////// //
// UI Settings //
// /////////// //

@Freezed(fromJson: true, toJson: true)
class UiSettings with _$UiSettings implements TomlEncodableValue {
  const UiSettings._();

  const factory UiSettings({
    @Default(Language.english) Language language,
    @Default(true) bool displayConfetti,
    @Default(ScreenTransitionAnimation.fadeAndScale) ScreenTransitionAnimation screenTransitionAnimation,
    @Default(FilterQuality.low) FilterQuality screenTransitionAnimationFilterQuality,
    @Default(FilterQuality.low) FilterQuality liveViewFilterQuality,
  }) = _UiSettings;

  factory UiSettings.withDefaults() => UiSettings.fromJson({});

  factory UiSettings.fromJson(Map<String, Object?> json) => _$UiSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();
}

// ////////////// //
// Debug Settings //
// ////////////// //

// @Freezed(fromJson: true, toJson: true)
// class DebugSettings with _$DebugSettings implements TomlEncodableValue {

//   const DebugSettings._();

//   const factory DebugSettings({

//   }) = _DebugSettings;

//   factory DebugSettings.withDefaults() => DebugSettings.fromJson({});

//   factory DebugSettings.fromJson(Map<String, Object?> json) => _$DebugSettingsFromJson(json);

//   @override
//   Map<String, dynamic> toTomlValue() => toJson();

// }
