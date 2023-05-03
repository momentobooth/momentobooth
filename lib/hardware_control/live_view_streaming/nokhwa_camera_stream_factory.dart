import 'dart:async';

import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream_factory.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NokhwaCameraStreamFactory extends LiveViewStreamFactory {

  final int _cameraPointer;

  // ////////////// //
  // Initialization //
  // ////////////// //

  NokhwaCameraStreamFactory._({required super.id, required super.friendlyName, required int cameraHandle}) : _cameraPointer = cameraHandle;

  static Future<NokhwaCameraStreamFactory> createAndOpen({required String id, required String friendlyName, required int texturePtr}) async {
    return NokhwaCameraStreamFactory._(
      id: id,
      friendlyName: friendlyName,
      cameraHandle: await rustLibraryApi.nokhwaOpenCamera(friendlyName: friendlyName, operations: [
        ImageOperation.cropToAspectRatio(3 / 2),
      ], texturePtr: texturePtr),
    );
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
