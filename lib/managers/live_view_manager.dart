import 'dart:ui' as ui;

import 'package:flutter_rust_bridge_example/hardware_control/live_view_streaming/live_view_stream.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:flutter_rust_bridge_example/models/hardware/live_view_streaming/nokhwa_camera.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:mobx/mobx.dart';

part 'live_view_manager.g.dart';

class LiveViewManager = LiveViewManagerBase with _$LiveViewManager;

/// Class containing global state for photos in the app
abstract class LiveViewManagerBase with Store {
  
  LiveViewStream? _liveViewStream;

  @readonly
  ui.Image? _lastFrameImage;

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
    Settings settings = SettingsManagerBase.instance.settings;
    String webcamId = settings.hardware.liveViewWebcamId;

    if (liveViewStream == null || liveViewStream.friendlyName != webcamId) {
      liveViewStream?.dispose();

      var cameras = await NokhwaCamera.getAllCameras();
      NokhwaCamera? camera = cameras.cast<NokhwaCamera?>().firstWhere((camera) => camera!.friendlyName == webcamId, orElse: () => null);
      LiveViewManagerBase.instance._liveViewStream = await camera?.openStream()
        ?..getStream().listen((frame) async {
          // New frame arrived
          LiveViewManagerBase.instance._lastFrameImage = await frame.toImage()
        }).onError(() {
          // Error
          
        });
    }
  });

}
