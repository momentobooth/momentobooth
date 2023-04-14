import 'package:flutter_rust_bridge_example/hardware_control/live_view_streaming/live_view_stream.dart';
import 'package:flutter_rust_bridge_example/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_api.generated.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_bridge.dart';

class NokhwaCameraStream extends LiveViewStream {

  final int _cameraPointer;

  // ////////////// //
  // Initialization //
  // ////////////// //

  NokhwaCameraStream._({required super.id, required super.friendlyName, required int cameraHandle}) : _cameraPointer = cameraHandle;

  static Future<NokhwaCameraStream> createAndOpen({required String id, required String friendlyName}) async {
    return NokhwaCameraStream._(
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
    return rustLibraryApi
      .nokhwaSetCameraCallback(cameraPtr: _cameraPointer, operations: [ImageOperation.cropToAspectRatio(3/2)])
      .map((rawImage) => LiveViewFrame(rawRgbaData: rawImage.rawRgbaData, width: rawImage.width, height: rawImage.height));
  }

  // //////////////// //
  // Deinitialization //
  // //////////////// //

  @override
  void dispose() {
    rustLibraryApi.nokhwaCloseCamera(cameraPtr: _cameraPointer);
    super.dispose();
  }

}
