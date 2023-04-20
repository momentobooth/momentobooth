import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

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

    final rawImage = RawImage(rawRgbaData: byteData.buffer.asUint8List(), width: image.width, height: image.height);
    return await rustLibraryApi.jpegEncode(rawImage: rawImage, quality: 80);
  }

}
