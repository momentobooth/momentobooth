import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/gphoto2.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/nokhwa.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view_model.dart' show UpdateSettingsCallback;

class ImagingDevicePage extends StatefulWidget {

  const ImagingDevicePage({super.key});

  @override
  State<ImagingDevicePage> createState() => _ImagingDevicePageState();
}

class _ImagingDevicePageState extends State<ImagingDevicePage> {
  LiveViewMethod get liveViewMethodSetting => getIt<SettingsManager>().settings.hardware.liveViewMethod;
  CaptureMethod get captureMethodSetting => getIt<SettingsManager>().settings.hardware.captureMethod;
  String get liveViewWebcamId => getIt<SettingsManager>().settings.hardware.liveViewWebcamId;
  String get gPhoto2CameraId => getIt<SettingsManager>().settings.hardware.gPhoto2CameraId;

  @override
  void initState() {
    super.initState();
    setImagingDeviceList();
  }

  @observable
  List<NokhwaCameraInfo> webcams2 = List<NokhwaCameraInfo>.empty();

  @observable
  List<GPhoto2CameraInfo> gPhoto2Cameras2 = List<GPhoto2CameraInfo>.empty();

  Future<void> setImagingDeviceList() async {
    unawaited(setWebcamList2());
    unawaited(setCameraList2());
  }
  Future<void> setWebcamList2() async => webcams2 = await NokhwaCamera.listCameras();
  Future<void> setCameraList2() async => gPhoto2Cameras2 = await GPhoto2Camera.listCameras();

  @computed
  ImagingMethod get imagingMethod {
    if (captureMethodSetting == CaptureMethod.liveViewSource) {
      return switch (liveViewMethodSetting) {
        LiveViewMethod.debugNoise => ImagingMethod.debugNoise,
        LiveViewMethod.webcam => ImagingMethod.webcam,
        LiveViewMethod.debugStaticImage => ImagingMethod.debugStaticImage,
        _ => ImagingMethod.custom
      };
    } else if (liveViewMethodSetting == LiveViewMethod.gphoto2 && captureMethodSetting == CaptureMethod.gPhoto2) {
      return ImagingMethod.gphoto2;
    } else {
      return ImagingMethod.custom;
    }
  }

  Future<void> updateSettings(UpdateSettingsCallback updateCallback) async {
    Settings currentSettings = getIt<SettingsManager>().settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await getIt<SettingsManager>().updateAndSave(updatedSettings);
  }

  void setImagingWebcam(NokhwaCameraInfo camera) {
    updateSettings((settings) => settings.copyWith.hardware(
      liveViewMethod: LiveViewMethod.webcam,
      captureMethod: CaptureMethod.liveViewSource,
      liveViewWebcamId: NokhwaCamera.fromCameraInfo(camera).id
    ));
  }

  void setImagingGPhoto2(GPhoto2CameraInfo camera) {
    updateSettings((settings) => settings.copyWith.hardware(
      liveViewMethod: LiveViewMethod.gphoto2,
      captureMethod: CaptureMethod.gPhoto2,
      gPhoto2CameraId: GPhoto2Camera.fromCameraInfo(camera).id
    ));
  }

  void setImagingStaticImage() {
    updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: LiveViewMethod.debugStaticImage, captureMethod: CaptureMethod.liveViewSource));
  }

  void setImagingStaticNoise() {
    updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: LiveViewMethod.debugNoise, captureMethod: CaptureMethod.liveViewSource));
  }

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Selecting an imaging device",
                style: FluentTheme.of(context).typography.title,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "To capture images, you need to select an imaging device such as a camera or a webcam. "
              "Please ensure that your desired imaging device is connected to your computer and properly configured. See the documentation for more information on supported devices and setup instructions. "
              "If you do not have an imaging device connected, you can proceed with a debug device for testing purposes.",
              style: FluentTheme.of(context).typography.body,
            ),
            SizedBox(height: 16.0),
            Observer(
              builder: (_) => _getImagingOptions()
            ),
          ],
        ),
      ),
    );
  }

  Widget _getImagingOptions() {
    return Row(
      spacing: 10.0,
      children: [
        _getImagingButton(LucideIcons.rotateCcw, 'Refresh', 'Refresh all devices', false, setImagingDeviceList),
        for (final webcam in webcams2) ...[
          _getImagingButton(
            LucideIcons.webcam,
            'Webcam',
            webcam.friendlyName,
            imagingMethod == ImagingMethod.webcam && liveViewWebcamId == webcam.friendlyName,
            () => setImagingWebcam(webcam),
          )
        ],
        for (final camera in gPhoto2Cameras2) ...[
          _getImagingButton(
            LucideIcons.camera,
            'Camera',
            '${camera.model}\nat ${camera.port}',
            imagingMethod == ImagingMethod.gphoto2 && gPhoto2CameraId == GPhoto2Camera.fromCameraInfo(camera).id,
            () => setImagingGPhoto2(camera),
          )
        ],
        _getImagingButton(
          LucideIcons.audioWaveform,
          "Static noise", "Debug option",
          imagingMethod == ImagingMethod.debugNoise,
          setImagingStaticNoise
        ),
        _getImagingButton(
          LucideIcons.image,
          "Static image",
          "Debug option",
          imagingMethod == ImagingMethod.debugStaticImage,
          setImagingStaticImage
        ),
      ],
    );
  }

  Widget _getImagingButton(IconData icon, String title, String subtitle, bool isSelected, VoidCallback onPressed) {
    return ToggleButton(
      checked: isSelected,
      onChanged: (v) => onPressed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      )
    );
  }
}
