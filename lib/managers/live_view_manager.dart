import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/noise_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/static_image_source.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Live View Manager";

  @readonly
  bool _lastFrameWasInvalid = false;

  @readonly
  GPhoto2Camera? _gPhoto2Camera;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  void initialize() {
    Timer.periodic(const Duration(seconds: 1), (_) => _checkLiveViewState());

    autorun((_) {
      // To make sure mobx detects that we are responding to changes to this property
      getIt<SettingsManager>().settings.hardware.liveViewWebcamId;
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

  Future<void> _disposeCurrentLiveViewSourceSafe() async {
    try {
      if (_currentLiveViewSource != null) {
        logDebug("Disconnecting ${_currentLiveViewSource?.friendlyName} of type ${_currentLiveViewSource.runtimeType}");
        await _currentLiveViewSource?.dispose();
        logDebug("Disconnected ${_currentLiveViewSource?.friendlyName} of type ${_currentLiveViewSource.runtimeType}");
      } else {
        logDebug("No current live view source to dispose");
      }
    } catch (e, s) {
      logError("Disposing of ${_currentLiveViewSource?.friendlyName} of type ${_currentLiveViewSource.runtimeType} failed", e, s);
    }
  }

  Future<void> _updateConfig() async {
    LiveViewMethod liveViewMethodSetting = getIt<SettingsManager>().settings.hardware.liveViewMethod;
    CaptureMethod captureMethodSetting = getIt<SettingsManager>().settings.hardware.captureMethod;
    String gPhoto2CameraIdSetting = getIt<SettingsManager>().settings.hardware.gPhoto2CameraId;
    String webcamIdSetting = getIt<SettingsManager>().settings.hardware.liveViewWebcamId;

    if (_currentLiveViewMethod == null || _currentLiveViewMethod != liveViewMethodSetting || _currentLiveViewWebcamId != webcamIdSetting || _currentCaptureMethod != captureMethodSetting || _currentGPhoto2CameraId != gPhoto2CameraIdSetting) {
      // Webcam was not initialized yet or webcam ID setting changed.
      reportSubsystemBusy(message: "Disconnecting live view source");
      await _disposeCurrentLiveViewSourceSafe();
      reportSubsystemBusy(message: "Connecting live view source");

      _currentLiveViewMethod = liveViewMethodSetting;
      _currentLiveViewWebcamId = webcamIdSetting;
      _currentCaptureMethod = captureMethodSetting;
      _currentGPhoto2CameraId = gPhoto2CameraIdSetting;

      // Special handling for gPhoto2 as gPhoto2 might be used for capture but not for live view.
      // Instead one might use a HDMI capture device for live view (when de camera does not support preview streaming).
      if (_gPhoto2Camera != null) {
        // Current live view source is already disposed, don't dispose the same camera instance twice.
        if (_gPhoto2Camera != _currentLiveViewSource) await _gPhoto2Camera!.dispose();
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
          await GPhoto2Camera.ensureLibraryInitialized(); // Fixes Hot Reload, as handles using (old) textures now get's closed before these old textures are being closed.
          _currentLiveViewSource = _gPhoto2Camera;
        case LiveViewMethod.debugStaticImage:
          _currentLiveViewSource = StaticImageSource();
      }

      try {
        _lastFrameWasInvalid = false;
        if (_currentLiveViewSource == null) throw Exception('Invalid camera selection');
        await _ensureTextureAvailable();
        await _currentLiveViewSource!.openStream(texturePtr: BigInt.from(_texturePointer));
        reportSubsystemOk();
        unawaited(_checkLiveViewState());
      } catch (e, s) {
        logError("Failed to open ${_currentLiveViewSource?.friendlyName} of type ${_currentLiveViewSource.runtimeType}", e, s);
        reportSubsystemBusy(message: 'Failed to open live view stream, disposing resources');
        await _disposeCurrentLiveViewSourceSafe();
        _currentLiveViewSource = null;
        reportSubsystemError(message: 'Failed to open live view stream', exception: e.toString(), actions: {
          'Restart stream': restoreLiveView,
        });
      }
    }
  }

  Future<void> _checkLiveViewState() async {
    await _updateLiveViewSourceInstanceLock.synchronized(() async {
      CameraState? liveViewState = await _currentLiveViewSource?.getCameraState();
      if (liveViewState == null || subsystemStatus is SubsystemStatusBusy) return;

      Duration? timeSinceLastFrame = liveViewState.timeSinceLastReceivedFrame;
      if (timeSinceLastFrame != null && timeSinceLastFrame > const Duration(seconds: 5)) {
        // Stop live view source and set error state.
        reportSubsystemError(message: "No frames received for 5 seconds, stopping");
        await _disposeCurrentLiveViewSourceSafe();
        reportSubsystemError(message: "No frames received for 5 seconds, stopped", actions: {
          'Restart stream': restoreLiveView,
        });
        _currentLiveViewSource = null;
      } else if (liveViewState.timeSinceLastReceivedFrame != null && !liveViewState.lastFrameWasValid) {
        // Camera still running but last frame could not be decoded.
        _lastFrameWasInvalid = true;
        reportSubsystemWarning(message: 'Last frame was invalid, total invalid frames: ${liveViewState.errorFrameCount}');
      } else {
        // Everything seems to be fine.
        getIt<StatsManager>()
          ..validLiveViewFrames = liveViewState.validFrameCount
          ..invalidLiveViewFrames = liveViewState.errorFrameCount
          ..duplicateLiveViewFrames = liveViewState.duplicateFrameCount;
        _lastFrameWasInvalid = false;

        _textureWidth = liveViewState.frameWidth;
        _textureHeight = liveViewState.frameHeight;

        reportSubsystemOk(message: 'Active and streaming, total valid frames: ${liveViewState.validFrameCount}');
      }
    });
  }

  // /////// //
  // Methods //
  // /////// //

  Future<void> restoreLiveView() async {
    await _updateLiveViewSourceInstanceLock.synchronized(() async {
      _currentLiveViewMethod = null;
      await _updateConfig();
    });
  }

}
