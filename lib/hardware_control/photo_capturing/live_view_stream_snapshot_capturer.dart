import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/photo_capture_method.dart';

class LiveViewStreamSnapshotCapturer implements PhotoCaptureMethod {

  @override
  Duration get captureDelay => Duration(milliseconds: 500);

  @override
  void capture() {
    print("FakeCaptureMethod: Capture");
  }

  @override
  Future<Uint8List> captureAndGetPhoto() {
    print("FakeCaptureMethod: Capture and Get Photo");
    return getPhoto();
  }

  @override
  Future<Uint8List> getPhoto() async {
    print("FakeCaptureMethod: Get Photo");
    ByteData bytes = await rootBundle.load('assets/bitmap/sample-background.jpg');
    return bytes.buffer.asUint8List();
  }
  
}
