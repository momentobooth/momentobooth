import 'dart:async';

import 'package:collection/collection.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/camera_state_extension.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/noise_source.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager extends _LiveViewManagerBase with _$LiveViewManager {

  static final LiveViewManager instance = LiveViewManager._internal();

  LiveViewManager._internal() : super._internal();

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

  _LiveViewManagerBase._internal() {
    Timer.periodic(const Duration(seconds: 1), (_) => _checkLiveViewState());
  }

  // /////// //
  // Texture //
  // /////// //

  @readonly
  int? _textureId;

  int? _texturePointer;

  Future<void> _ensureTextureAvailable() async {
    if (_textureId != null) return;

    // Initialize texture
    const int textureKey = 0;
    var textureRenderer = TextureRgbaRenderer();
    await textureRenderer.closeTexture(textureKey);
    _textureId = await textureRenderer.createTexture(textureKey);
    _texturePointer = await textureRenderer.getTexturePtr(textureKey);
  }

  // ///////// //
  // Reactions //
  // ///////// //

  final Lock _lock = Lock();

  @readonly
  LiveViewSource? _currentLiveViewSource;

  LiveViewMethod? _currentLiveViewMethodSetting;
  String? _currentLiveViewWebcamId;

  CaptureMethod? _currentCaptureMethodSetting;

  String? _currentGPhoto2CameraId;

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  final ReactionDisposer onSettingsChangedDisposer = autorun((_) {
    // To make sure mobx detects that we are responding to changed to this property
    SettingsManager.instance.settings.hardware.liveViewWebcamId;
    LiveViewManager.instance._lock.synchronized(() async {
      await LiveViewManager.instance._updateConfig();
    });
  });

  Future<void> _updateConfig() async {
    LiveViewMethod liveViewMethodSetting = SettingsManager.instance.settings.hardware.liveViewMethod;
    CaptureMethod captureMethodSetting = SettingsManager.instance.settings.hardware.captureMethod;
    String gPhoto2CameraId = SettingsManager.instance.settings.hardware.gPhoto2CameraId;
    String webcamIdSetting = SettingsManager.instance.settings.hardware.liveViewWebcamId;

    if (_currentLiveViewMethodSetting == null || _currentLiveViewMethodSetting != liveViewMethodSetting || _currentLiveViewWebcamId != webcamIdSetting || _currentCaptureMethodSetting != captureMethodSetting || _currentGPhoto2CameraId != gPhoto2CameraId) {
      // Webcam was not initialized yet or webcam ID setting changed
      _liveViewState = LiveViewState.initializing;
      await _currentLiveViewSource?.dispose();

      _currentLiveViewMethodSetting = liveViewMethodSetting;
      _currentLiveViewWebcamId = webcamIdSetting;
      _currentCaptureMethodSetting = captureMethodSetting;
      _currentGPhoto2CameraId = gPhoto2CameraId;

      // GPhoto2
      if (_gPhoto2Camera != null && _gPhoto2Camera!.isOpened) {
        await _gPhoto2Camera!.dispose();
        _gPhoto2Camera = null;
      }
      if ((liveViewMethodSetting == LiveViewMethod.gphoto2 || captureMethodSetting == CaptureMethod.gPhoto2) && gPhoto2CameraId.isNotEmpty) {
        _gPhoto2Camera = GPhoto2Camera(id: gPhoto2CameraId, friendlyName: gPhoto2CameraId);
      }

      switch (liveViewMethodSetting) {
        case LiveViewMethod.debugNoise:
          _currentLiveViewSource = NoiseSource();
        case LiveViewMethod.webcam:
          List<NokhwaCamera> cameras = await NokhwaCamera.getAllCameras();
          _currentLiveViewSource = cameras.firstWhereOrNull((camera) => camera.friendlyName == webcamIdSetting);
        case LiveViewMethod.gphoto2:
          _currentLiveViewSource = _gPhoto2Camera;
        default:
          throw "Unknown live view method";
      }

      await _ensureTextureAvailable();
      await _currentLiveViewSource?.openStream(texturePtr: _texturePointer!);

      _liveViewState = LiveViewState.streaming;
      _lastFrameWasInvalid = false;
    }
  }

  Future<void> _checkLiveViewState() async {
    _lock.synchronized(() async {
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
        _lastFrameWasInvalid = false;
      }
    });
  }

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
