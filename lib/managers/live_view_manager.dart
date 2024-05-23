import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/extensions/camera_state_extension.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/noise_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/static_image_source.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager extends _LiveViewManagerBase with _$LiveViewManager {

  static final LiveViewManager instance = LiveViewManager._internal();

  LiveViewManager._internal();

}

/// Class containing global state for photos in the app
abstract class _LiveViewManagerBase with Store {

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
  int? _textureWidth, _textureHeight;

  @readonly
  int? _textureId;

  late int _texturePointer;

  Future<void> _ensureTextureAvailable() async {
    if (_textureId != null) return;
    var textureRenderer = TextureRgbaRenderer();

    // Initialize main texture
    const int textureKeyMain = 0;
    await textureRenderer.closeTexture(textureKeyMain);
    _textureId = await textureRenderer.createTexture(textureKeyMain);
    _texturePointer = await textureRenderer.getTexturePtr(textureKeyMain);
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

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  Future<void> _updateConfig() async {
    LiveViewMethod liveViewMethodSetting = SettingsManager.instance.settings.hardware.liveViewMethod;
    CaptureMethod captureMethodSetting = SettingsManager.instance.settings.hardware.captureMethod;
    String gPhoto2CameraIdSetting = SettingsManager.instance.settings.hardware.gPhoto2CameraId;
    String webcamIdSetting = SettingsManager.instance.settings.hardware.liveViewWebcamId;

    if (_currentLiveViewMethod == null || _currentLiveViewMethod != liveViewMethodSetting || _currentLiveViewWebcamId != webcamIdSetting || _currentCaptureMethod != captureMethodSetting || _currentGPhoto2CameraId != gPhoto2CameraIdSetting) {
      // Webcam was not initialized yet or webcam ID setting changed
      _liveViewState = LiveViewState.initializing;
      await _currentLiveViewSource?.dispose();

      _currentLiveViewMethod = liveViewMethodSetting;
      _currentLiveViewWebcamId = webcamIdSetting;
      _currentCaptureMethod = captureMethodSetting;
      _currentGPhoto2CameraId = gPhoto2CameraIdSetting;

      // GPhoto2
      if (_gPhoto2Camera != null) {
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
        case LiveViewMethod.debugStaticImage:
          _currentLiveViewSource = StaticImageSource();
      }

      await _ensureTextureAvailable();
      await _currentLiveViewSource?.openStream(
        texturePtr: BigInt.from(_texturePointer),
      );

      _liveViewState = LiveViewState.streaming;
      _lastFrameWasInvalid = false;
    }
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
        getIt<StatsManager>()
          ..validLiveViewFrames = liveViewState.validFrameCount
          ..invalidLiveViewFrames = liveViewState.errorFrameCount
          ..duplicateLiveViewFrames = liveViewState.duplicateFrameCount;
        _lastFrameWasInvalid = false;

        _textureWidth = liveViewState.frameWidth;
        _textureHeight = liveViewState.frameHeight;
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
