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
    required bool displayConfetti,
    required double collageAspectRatio,
    required double collagePadding,
    required bool singlePhotoIsCollage,
    required String templatesFolder,
    required HardwareSettings hardware,
    required OutputSettings output,
  }) = _Settings;

  factory Settings.withDefaults() {
    return Settings(
      captureDelaySeconds: 5,
      collageAspectRatio: 1.5,
      collagePadding: 0,
      displayConfetti: true,
      singlePhotoIsCollage: true,
      templatesFolder: _getHome(),
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
    required String liveViewWebcamId,
    required Flip liveViewFlipImage,
    required CaptureMethod captureMethod,
    required int captureDelaySony,
    required String captureLocation,
    required String printerName,
    required double pageHeight,
    required double pageWidth,
    required bool usePrinterSettings,
    required double printerMarginTop,
    required double printerMarginRight,
    required double printerMarginBottom,
    required double printerMarginLeft,
  }) = _HardwareSettings;

  factory HardwareSettings.withDefaults() {
    return HardwareSettings(
      liveViewMethod: LiveViewMethod.webcam,
      liveViewWebcamId: "",
      liveViewFlipImage: Flip.horizontally,
      captureMethod: CaptureMethod.liveViewSource,
      captureDelaySony: 200,
      captureLocation: _getHome(),
      printerName: "",
      pageHeight: 148,
      pageWidth: 100,
      usePrinterSettings: true,
      printerMarginTop: 0,
      printerMarginRight: 0,
      printerMarginBottom: 0,
      printerMarginLeft: 0,
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
    required int jpgQuality,
    required double resolutionMultiplier,
    required ExportFormat exportFormat,
    required String firefoxSendServerUrl,
  }) = _OutputSettings;

  factory OutputSettings.withDefaults() {
    return OutputSettings(
      localFolder: join(_getHome(), "Pictures"),
      jpgQuality: 80,
      resolutionMultiplier: 4.0,
      exportFormat: ExportFormat.jpgFormat,
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
