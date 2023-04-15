import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:flutter_rust_bridge_example/managers/live_view_manager.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_bridge.dart';

class LiveViewStreamSnapshotCapturer implements PhotoCaptureMethod {

  @override
  Duration get captureDelay => Duration.zero;

  @override
  Future<Uint8List> captureAndGetPhoto() async {
    ui.Image? image = LiveViewManagerBase.instance.lastFrameImage;
    if (image == null) {
      throw "No frame available for capture";
    }
    ByteData? byteData = await image.toByteData();
    if (byteData == null) {
      throw "Could not encode frame to byte data";
    }

    return await rustLibraryApi.jpegEncode(width: image.width, height: image.height, data: byteData.buffer.asUint8List(), quality: 80);
  }

}
