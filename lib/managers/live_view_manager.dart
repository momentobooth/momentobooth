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

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase with Store, UiLoggy {

  final Lock _lock = Lock();
  
  LiveViewStreamFactory? _liveViewStream;
  StreamSubscription<LiveViewFrame>? _liveViewSubscription;

  @observable
  ui.Image? _lastFrameImage;

  @computed
  ui.Image? get lastFrameImage => _lastFrameImage;

  set lastFrameImage(ui.Image? image) {
    ui.Image? previousLastFrameImage = _lastFrameImage;
    _lastFrameImage = image;
    previousLastFrameImage?.dispose();
    StatsManagerBase.instance.addLiveViewFrame();
  }

  @readonly
  LiveViewState _liveViewState = LiveViewState.initializing;

  static const int _fps = 60; // TDDO: detect from screen instead of guessing
  static const double _minimumFrameTimeMs = 1000 / _fps;
  final Stopwatch _timeFromLastReceivedFrame = Stopwatch()..start();

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

        _liveViewSubscription = stream.getStream().listen((frame) async {
          // New frame arrived
          if (_timeFromLastReceivedFrame.elapsedMilliseconds < LiveViewManagerBase._minimumFrameTimeMs) {
            StatsManagerBase.instance.addLiveViewFrameDroppedByConsumer();
          } else {
            frameOrderLock.synchronized(() async {
              lastFrameImage = await frame.toImage();
              _liveViewState = LiveViewState.streaming;
            });
          }
          _timeFromLastReceivedFrame.reset();
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
