import 'dart:async';
import 'dart:ui' as ui;

import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream_factory.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:momento_booth/models/hardware/live_view_streaming/nokhwa_camera.dart';
import 'package:mobx/mobx.dart';
import 'package:synchronized/synchronized.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase with Store, UiLoggy {

  final Lock _lock = Lock();
  
  LiveViewStreamFactory? _liveViewStream;
  StreamSubscription<LiveViewFrame>? _liveViewSubscription;

  @readonly
  int? _textureId;

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  // ////////////// //
  // Initialization //
  // ////////////// //

  static final LiveViewManager instance = LiveViewManager._internal();

  LiveViewManagerBase._internal();

  // ///////// //
  // Reactions //
  // ///////// //

  final ReactionDisposer onSettingsChangedDisposer = autorun((_) {
    // To make sure mobx detects that we are responding to changed to this property
    SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;
    LiveViewManagerBase.instance._lock.synchronized(() async {
      await LiveViewManagerBase.instance._updateConfig();
    });
  });

  Future<void> _updateConfig() async {
    LiveViewStreamFactory? liveViewStream = _liveViewStream;
    String webcamIdSetting = SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;

    if (liveViewStream == null || liveViewStream.friendlyName != webcamIdSetting) {
      // Webcam was not initialized yet or webcam ID setting changed
      _liveViewState = LiveViewState.initializing;
      await _liveViewSubscription?.cancel();
      await _liveViewStream?.dispose();

      _liveViewSubscription = null;
      _liveViewStream = null;

      var cameras = await NokhwaCamera.getAllCameras();
      NokhwaCamera? camera = cameras
          .cast<NokhwaCamera?>()
          .firstWhere((camera) => camera!.friendlyName == webcamIdSetting, orElse: () => null);
      try {
        var stream = _liveViewStream = await camera?.openStream();
        if (stream == null) {
          return;
        }

        Lock frameOrderLock = Lock();

        var textureRenderer = TextureRgbaRenderer();
        _textureId = await textureRenderer.createTexture(0);

        _liveViewSubscription = stream.getStream().listen((frame) async {
          // New frame arrived
          frameOrderLock.synchronized(() async {
            _liveViewState = LiveViewState.streaming;
            await textureRenderer.onRgba(0, frame.rawRgbaData, frame.height, frame.width, 0);
          });
        }, onError: (error) {
          // Error
          _liveViewState = LiveViewState.error;
          loggy.error("Error while streaming from '$webcamIdSetting'", error);
        }, cancelOnError: true);
      } catch (error) {
        _liveViewState = LiveViewState.error;
        loggy.error("Failed to open camera '$webcamIdSetting'", error);
      }
    }
  }

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
