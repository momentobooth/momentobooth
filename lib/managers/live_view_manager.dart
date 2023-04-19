import 'dart:ui' as ui;

import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/hardware/live_view_streaming/nokhwa_camera.dart';
import 'package:mobx/mobx.dart';

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase with Store {
  
  LiveViewStream? _liveViewStream;

  @readonly
  ui.Image? _lastFrameImage;

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

  final ReactionDisposer onSettingsChangedDisposer = autorun((_) async {
    LiveViewStream? liveViewStream = LiveViewManagerBase.instance._liveViewStream;
    String webcamIdSetting = SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;

    if (liveViewStream == null || liveViewStream.friendlyName != webcamIdSetting) {
      // Webcam was not initialized yet or webcam ID setting changed
      LiveViewManagerBase.instance._liveViewState = LiveViewState.initializing;
      await liveViewStream?.dispose();

      var cameras = await NokhwaCamera.getAllCameras();
      NokhwaCamera? camera = cameras.cast<NokhwaCamera?>().firstWhere((camera) => camera!.friendlyName == webcamIdSetting, orElse: () => null);
      try {
        LiveViewManagerBase.instance._liveViewStream = await camera?.openStream()
          ?..getStream().listen((frame) async {
            // New frame arrived
            LiveViewManagerBase.instance._lastFrameImage = await frame.toImage();
            LiveViewManagerBase.instance._liveViewState = LiveViewState.streaming;
          }).onError((error) {
            // Error
            LiveViewManagerBase.instance._liveViewState = LiveViewState.error;
          });
      }
      catch (error) {
        LiveViewManagerBase.instance._liveViewState = LiveViewState.error;
      }
    }
  });

}

enum LiveViewState {
  initializing,
  error,
  streaming,
}
