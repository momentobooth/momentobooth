import 'dart:async';

import 'package:collection/collection.dart';
import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/extensions/camera_state_extension.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/noise_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager extends _LiveViewManagerBase with _$LiveViewManager {

  static final LiveViewManager instance = LiveViewManager._internal();

  LiveViewManager._internal();

}

/// Class containing global state for photos in the app
abstract class _LiveViewManagerBase with Store, UiLoggy {

  @readonly
  bool _lastFrameWasInvalid = false;

  @readonly
  GPhoto2Camera? _gPhoto2Camera;

  // ////////////// //
  // Initialization //
  // ////////////// //

  void initialize() {
    Timer.periodic(const Duration(seconds: 1), (_) => _checkLiveViewState());

    autorun((_) {
      // To make sure mobx detects that we are responding to changes to this property
      SettingsManager.instance.settings.hardware.liveViewWebcamId;
      _updateLiveViewSourceInstanceLock.synchronized(() async {
        await _updateConfig();
      });
    });
  }

  // /////// //
  // Texture //
  // /////// //

  @readonly
  int? _textureIdMain;

  int? _texturePointerMain;

  @readonly
  int? _textureIdBlur;

  int? _texturePointerBlur;

  Future<void> _ensureTextureAvailable() async {
    if (_textureIdMain != null) return;
    var textureRenderer = TextureRgbaRenderer();

    // Initialize main texture
    const int textureKeyMain = 0;
    await textureRenderer.closeTexture(textureKeyMain);
    _textureIdMain = await textureRenderer.createTexture(textureKeyMain);
    _texturePointerMain = await textureRenderer.getTexturePtr(textureKeyMain);

    // Initialize blurred texture
    const int textureKeyBlur = 1;
    await textureRenderer.closeTexture(textureKeyBlur);
    _textureIdBlur = await textureRenderer.createTexture(textureKeyBlur);
    _texturePointerBlur = await textureRenderer.getTexturePtr(textureKeyBlur);
  }

  // ///////// //
  // Reactions //
  // ///////// //

  final Lock _updateLiveViewSourceInstanceLock = Lock();

  @readonly
  LiveViewSource? _currentLiveViewSource;

  LiveViewMethod? _currentLiveViewMethod;
  String? _currentLiveViewWebcamId;
  CaptureMethod? _currentCaptureMethod;
  String? _currentGPhoto2CameraId;
  Flip? _currentliveViewFlip;
  double? _currentLiveViewAndCaptureAspectRatio;

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  Future<void> _updateConfig() async {
    LiveViewMethod liveViewMethodSetting = SettingsManager.instance.settings.hardware.liveViewMethod;
    CaptureMethod captureMethodSetting = SettingsManager.instance.settings.hardware.captureMethod;
    String gPhoto2CameraIdSetting = SettingsManager.instance.settings.hardware.gPhoto2CameraId;
    String webcamIdSetting = SettingsManager.instance.settings.hardware.liveViewWebcamId;
    Flip liveViewFlipSetting = SettingsManager.instance.settings.hardware.liveViewFlipImage;
    double liveViewAndCaptureAspectRatioSetting = SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio;

    if (_currentLiveViewMethod == null || _currentLiveViewMethod != liveViewMethodSetting || _currentLiveViewWebcamId != webcamIdSetting || _currentCaptureMethod != captureMethodSetting || _currentGPhoto2CameraId != gPhoto2CameraIdSetting || _currentliveViewFlip != liveViewFlipSetting || _currentLiveViewAndCaptureAspectRatio != liveViewAndCaptureAspectRatioSetting) {
      // Webcam was not initialized yet or webcam ID setting changed
      _liveViewState = LiveViewState.initializing;
      await _currentLiveViewSource?.dispose();

      _currentLiveViewMethod = liveViewMethodSetting;
      _currentLiveViewWebcamId = webcamIdSetting;
      _currentCaptureMethod = captureMethodSetting;
      _currentGPhoto2CameraId = gPhoto2CameraIdSetting;
      _currentliveViewFlip = liveViewFlipSetting;
      _currentLiveViewAndCaptureAspectRatio = liveViewAndCaptureAspectRatioSetting;

      // GPhoto2
      if (_gPhoto2Camera != null && _gPhoto2Camera!.isOpened) {
        await _gPhoto2Camera!.dispose();
        _gPhoto2Camera = null;
      }
      if ((liveViewMethodSetting == LiveViewMethod.gphoto2 || captureMethodSetting == CaptureMethod.gPhoto2) && gPhoto2CameraIdSetting.isNotEmpty) {
        _gPhoto2Camera = GPhoto2Camera(id: gPhoto2CameraIdSetting, friendlyName: gPhoto2CameraIdSetting);
      }

      switch (liveViewMethodSetting) {
        case LiveViewMethod.debugNoise:
          _currentLiveViewSource = NoiseSource();
        case LiveViewMethod.webcam:
          List<NokhwaCamera> cameras = await NokhwaCamera.getAllCameras();
          _currentLiveViewSource = cameras.firstWhereOrNull((camera) => camera.friendlyName == webcamIdSetting);
        case LiveViewMethod.gphoto2:
          _currentLiveViewSource = _gPhoto2Camera;
      }

      await _ensureTextureAvailable();
      await _currentLiveViewSource?.openStream(
        texturePtrMain: _texturePointerMain!,
        texturePtrBlur: _texturePointerBlur!,
        operations: _getImageOperations(),
      );

      _liveViewState = LiveViewState.streaming;
      _lastFrameWasInvalid = false;
    }
  }

  List<ImageOperation> _getImageOperations() {
    return [
      ImageOperation.cropToAspectRatio(SettingsManager.instance.settings.collageAspectRatio),
      if (SettingsManager.instance.settings.hardware.liveViewFlipImage == Flip.horizontally)
        const ImageOperation.flip(FlipAxis.Horizontally),
      if (SettingsManager.instance.settings.hardware.liveViewFlipImage == Flip.vertically)
        const ImageOperation.flip(FlipAxis.Vertically),
    ];
  }

  Future<void> _checkLiveViewState() async {
    await _updateLiveViewSourceInstanceLock.synchronized(() async {
      var liveViewState = await _currentLiveViewSource?.getCameraState();
      if (liveViewState == null) return;

      if (liveViewState.streamHasProbablyFailed) {
        // Stop live view source and set error state
        await _currentLiveViewSource?.dispose();
        _currentLiveViewSource = null;
        _liveViewState = LiveViewState.error;
        // TODO: restart automatically?
      } else if (!liveViewState.lastFrameWasValid) {
        // Camera still running but last frame could not be decoded
        _lastFrameWasInvalid = true;
      } else {
        // Everything seems to be fine
        StatsManager.instance.validLiveViewFrames = liveViewState.validFrameCount;
        StatsManager.instance.invalidLiveViewFrames = liveViewState.errorFrameCount;
        StatsManager.instance.duplicateLiveViewFrames = liveViewState.duplicateFrameCount;
        _lastFrameWasInvalid = false;
      }
    });
  }

  // /////// //
  // Methods //
  // /////// //

  void restoreLiveView() {
    LiveViewManager.instance._updateLiveViewSourceInstanceLock.synchronized(() async {
      _currentLiveViewMethod = null;
      await LiveViewManager.instance._updateConfig();
    });
  }

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
