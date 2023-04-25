import 'dart:async';
import 'dart:ui' as ui;

import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream_factory.dart';
import 'package:momento_booth/managers/settings_manager.dart';
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
  }

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
    LiveViewManagerBase.instance._lock.synchronized(() async {
      LiveViewStreamFactory? liveViewStream = LiveViewManagerBase.instance._liveViewStream;
      String webcamIdSetting = SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;

      if (liveViewStream == null || liveViewStream.friendlyName != webcamIdSetting) {
        // Webcam was not initialized yet or webcam ID setting changed
        LiveViewManagerBase.instance._liveViewState = LiveViewState.initializing;
        await LiveViewManagerBase.instance._liveViewSubscription?.cancel();
        await LiveViewManagerBase.instance._liveViewStream?.dispose();

        LiveViewManagerBase.instance._liveViewSubscription = null;
        LiveViewManagerBase.instance._liveViewStream = null;

        var cameras = await NokhwaCamera.getAllCameras();
        NokhwaCamera? camera = cameras
            .cast<NokhwaCamera?>()
            .firstWhere((camera) => camera!.friendlyName == webcamIdSetting, orElse: () => null);
        try {
          var stream = LiveViewManagerBase.instance._liveViewStream = await camera?.openStream();
          if (stream == null) {
            return;
          }

          LiveViewManagerBase.instance._liveViewSubscription = stream.getStream().listen((frame) async {
            // New frame arrived
            LiveViewManagerBase.instance.lastFrameImage = await frame.toImage();
            LiveViewManagerBase.instance._liveViewState = LiveViewState.streaming;
          }, onError: (error) {
            // Error
            LiveViewManagerBase.instance._liveViewState = LiveViewState.error;
            LiveViewManagerBase.instance.loggy.error("Error while streaming from '$webcamIdSetting'", error);
          }, cancelOnError: true);
        } catch (error) {
          LiveViewManagerBase.instance._liveViewState = LiveViewState.error;
          LiveViewManagerBase.instance.loggy.error("Failed to open camera '$webcamIdSetting'", error);
        }
      }
    });
  });

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
