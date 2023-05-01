import 'dart:async';

import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream_factory.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NokhwaCameraStreamFactory extends LiveViewStreamFactory {

  final int _cameraPointer;

  // ////////////// //
  // Initialization //
  // ////////////// //

  NokhwaCameraStreamFactory._({required super.id, required super.friendlyName, required int cameraHandle}) : _cameraPointer = cameraHandle;

  static Future<NokhwaCameraStreamFactory> createAndOpen({required String id, required String friendlyName}) async {
    return NokhwaCameraStreamFactory._(
      id: id,
      friendlyName: friendlyName,
      cameraHandle: await rustLibraryApi.nokhwaOpenCamera(friendlyName: friendlyName),
    );
  }

  // /////// //
  // Methods //
  // /////// //

  @override
  Stream<LiveViewFrame> getStream() {
    return rustLibraryApi.nokhwaSetCameraCallback(cameraPtr: _cameraPointer, operations: [
      ImageOperation.cropToAspectRatio(3 / 2)
    ]).map((liveCameraFrame) {
      StatsManagerBase.instance.addLiveViewFramesDroppedByCameraImplementation(liveCameraFrame.skippedFrames);
      return LiveViewFrame(
        rawRgbaData: liveCameraFrame.rawImage.data,
        width: liveCameraFrame.rawImage.width,
        height: liveCameraFrame.rawImage.height,
      );
    });
  }

  // //////////////// //
  // Deinitialization //
  // //////////////// //

  @override
  Future dispose() async {
    await rustLibraryApi.nokhwaCloseCamera(cameraPtr: _cameraPointer);
    await super.dispose();
  }

}
