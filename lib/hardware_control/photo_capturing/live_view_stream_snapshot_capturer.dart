import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class LiveViewStreamSnapshotCapturer with UiLoggy implements PhotoCaptureMethod {

  @override
  Duration get captureDelay => Duration(milliseconds: -17);

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

    final rawImage = RawImage(format: RawImageFormat.Rgba, data: byteData.buffer.asUint8List(), width: image.width, height: image.height);

    final stopwatch = Stopwatch()..start();
    final jpegData = await rustLibraryApi.jpegEncode(rawImage: rawImage, quality: 80, operationsBeforeEncoding: []);
    loggy.debug('JPEG encoding took ${stopwatch.elapsed}');

    return jpegData;
  }

}
