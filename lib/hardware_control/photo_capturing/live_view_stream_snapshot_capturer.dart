import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class LiveViewStreamSnapshotCapturer extends PhotoCaptureMethod with UiLoggy {

  @override
  Duration get captureDelay => const Duration(milliseconds: -17);

  @override
  Future<Uint8List> captureAndGetPhoto() async {
    final rawImage = await LiveViewManager.instance.currentLiveViewSource?.getLastFrame();
    final jpegData = await rustLibraryApi.jpegEncode(rawImage: rawImage!, quality: 80, operationsBeforeEncoding: []);

    await storePhotoSafe('liveview.jpg', jpegData);

    return jpegData;
  }
  
  @override
  Future<void> clearPreviousEvents() async {}

}
