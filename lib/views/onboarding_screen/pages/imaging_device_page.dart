import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/gphoto2.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/nokhwa.dart';
import 'package:momento_booth/views/components/imaging/live_view.dart';
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
  bool prevConfigError = false;

  @override
  void initState() {
    super.initState();
    setImagingDeviceList();
    var isFirstConfig = liveViewWebcamId.isEmpty && gPhoto2CameraId.isEmpty || !getIt<SettingsManager>().settings.onboardingStepsDone.contains(OnboardingStep.setupImagingDevice);
    prevConfigError = getIt<LiveViewManager>().subsystemStatus is! SubsystemStatusOk && !isFirstConfig;
  }

  bool updatingCameraList = true;
  List<NokhwaCameraInfo> webcams = const [];
  List<GPhoto2CameraInfo> gPhoto2Cameras = const [];

  Future<void> setImagingDeviceList() async {
    setState(() => updatingCameraList = true);

    var webcams = await NokhwaCamera.listCameras();
    var gPhoto2Cameras = await GPhoto2Camera.listCameras();

    setState(() {
      this.webcams = webcams;
      this.gPhoto2Cameras = gPhoto2Cameras;
      updatingCameraList = false;
    });
  }

  @computed
  ImagingMethod get imagingMethod {
    if (captureMethodSetting == CaptureMethod.liveViewSource) {
      return switch (liveViewMethodSetting) {
        LiveViewMethod.debugNoise => ImagingMethod.debugNoise,
        LiveViewMethod.webcam => ImagingMethod.webcam,
        LiveViewMethod.debugStaticImage => ImagingMethod.debugStaticImage,
        _ => ImagingMethod.custom,
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
    setState(() { prevConfigError = false; });
    updateSettings((settings) => settings.copyWith.hardware(
      liveViewMethod: LiveViewMethod.webcam,
      captureMethod: CaptureMethod.liveViewSource,
      liveViewWebcamId: NokhwaCamera.fromCameraInfo(camera).id,
    ));
  }

  void setImagingGPhoto2(GPhoto2CameraInfo camera) {
    setState(() { prevConfigError = false; });
    updateSettings((settings) => settings.copyWith.hardware(
      liveViewMethod: LiveViewMethod.gphoto2,
      captureMethod: CaptureMethod.gPhoto2,
      gPhoto2CameraId: GPhoto2Camera.fromCameraInfo(camera).id,
    ));
  }

  void setImagingStaticImage() {
    setState(() { prevConfigError = false; });
    updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: LiveViewMethod.debugStaticImage, captureMethod: CaptureMethod.liveViewSource));
  }

  void setImagingStaticNoise() {
    setState(() { prevConfigError = false; });
    updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: LiveViewMethod.debugNoise, captureMethod: CaptureMethod.liveViewSource));
  }

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16.0,
          children: [
            Center(
              child: Text(
                "Selecting an imaging device",
                style: FluentTheme.of(context).typography.title,
              ),
            ),
            Text(
              "To capture images, you need to select an imaging device such as a camera or a webcam. "
              "Please ensure that your desired imaging device is connected to your computer and properly configured. See the documentation for more information on supported devices and setup instructions. "
              "If you do not have an imaging device connected, you can proceed with a debug device for testing purposes.",
              style: FluentTheme.of(context).typography.body,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16.0,
                children: [
                  Expanded(
                    flex: 1,
                    child: Observer(builder: (_) => Column(
                      children: [
                        if (prevConfigError) ...[
                          InfoBar(
                            title: const Text('Problem with imaging device'),
                            content: const Text(
                                'The previously selected imaging device is not available or not properly configured.'),
                            severity: InfoBarSeverity.warning,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Expanded(child: _getImagingOptions())
                      ]
                    )),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      spacing: 16.0,
                      children: [
                        Text(
                          "Preview of the selected imaging device:",
                          style: FluentTheme.of(context).typography.body,
                        ),
                        Expanded(
                          flex: 1,
                          child: getIt<LiveViewManager>().subsystemStatus is SubsystemStatusOk
                              ? LiveView(fit: BoxFit.contain, applyPostProcessing: false)
                              : Placeholder(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ScrollController _gvScrollController = ScrollController();

  Widget _getImagingOptions() {
    // Using ScrollConfiguration to disable the scrollbar of the GridView,
    // else we have two scrollbars (one from the GridView and one from the Scrollbar widget).
    // The GridView itself does not have a property to always *show* the scrollbar, so the Scrollbar widget must be used.
    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: Scrollbar(
        controller: _gvScrollController,
        thumbVisibility: true,
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          padding: EdgeInsets.only(right: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _gvScrollController,
          children: [
            _getImagingButton(LucideIcons.rotateCcw, 'Refresh', 'Refresh all devices', false, updatingCameraList ? null : setImagingDeviceList),
            for (final webcam in webcams) ...[
              _getImagingButton(
                LucideIcons.webcam,
                'Webcam',
                webcam.friendlyName,
                imagingMethod == ImagingMethod.webcam && liveViewWebcamId == webcam.friendlyName,
                () => setImagingWebcam(webcam),
              )
            ],
            for (final camera in gPhoto2Cameras) ...[
              _getImagingButton(
                LucideIcons.camera,
                'Camera',
                camera.model,
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
        ),
      ),
    );
  }

  Widget _getImagingButton(IconData icon, String title, String subtitle, bool isSelected, VoidCallback? onPressed) {
    return ToggleButton(
      checked: isSelected,
      onChanged: onPressed != null ? (v) => onPressed() : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

}
