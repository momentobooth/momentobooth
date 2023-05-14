import 'dart:async';

import 'package:collection/collection.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/noise_source.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase with Store, UiLoggy {

  // ////////////// //
  // Initialization //
  // ////////////// //

  static final LiveViewManager instance = LiveViewManager._internal();

  LiveViewManagerBase._internal();

  // /////// //
  // Texture //
  // /////// //

  @readonly
  int? _textureId;

  int? _texturePointer;

  Future<void> _ensureTextureAvailable() async {
    if (_textureId != null) {
      return;
    }

    // Initialize texture
    const int textureKey = 0;
    var textureRenderer = TextureRgbaRenderer();
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

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  final ReactionDisposer onSettingsChangedDisposer = autorun((_) {
    // To make sure mobx detects that we are responding to changed to this property
    SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;
    LiveViewManagerBase.instance._lock.synchronized(() async {
      await LiveViewManagerBase.instance._updateConfig();
    });
  });

  Future<void> _updateConfig() async {
    LiveViewMethod liveViewMethodSetting = SettingsManagerBase.instance.settings.hardware.liveViewMethod;
    String webcamIdSetting = SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;

    if (_currentLiveViewMethodSetting == null || _currentLiveViewMethodSetting != liveViewMethodSetting || _currentLiveViewWebcamId != webcamIdSetting) {
      // Webcam was not initialized yet or webcam ID setting changed
      _liveViewState = LiveViewState.initializing;
      await _currentLiveViewSource?.dispose();

      _currentLiveViewMethodSetting = liveViewMethodSetting;
      _currentLiveViewWebcamId = webcamIdSetting;

      switch (liveViewMethodSetting) {
        case LiveViewMethod.debugNoise:
          _currentLiveViewSource = NoiseSource();
        case LiveViewMethod.webcam:
          List<NokhwaCamera> cameras = await NokhwaCamera.getAllCameras();
          _currentLiveViewSource = cameras.firstWhereOrNull((camera) => camera.friendlyName == webcamIdSetting);
        default:
          throw "Unknown live view method";
      }

      await _ensureTextureAvailable();
      await _currentLiveViewSource?.openStream(texturePtr: _texturePointer!);

      _liveViewState = LiveViewState.streaming;
    }
  }

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
