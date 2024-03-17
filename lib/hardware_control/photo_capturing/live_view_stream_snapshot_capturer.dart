import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/src/rust/api/simple.dart';
import 'package:momento_booth/utils/platform_and_app.dart';

class LiveViewStreamSnapshotCapturer extends PhotoCaptureMethod with UiLoggy {

  @override
  Duration get captureDelay => const Duration(milliseconds: -17);

  @override
  Future<PhotoCapture> captureAndGetPhoto() async {
    final rawImage = await LiveViewManager.instance.currentLiveViewSource?.getLastFrame();
    final jpegData = await jpegEncode(
      rawImage: rawImage!,
      quality: 80,
      exifTags: [
        const MomentoBoothExifTag.imageDescription("Live view capture"),
        MomentoBoothExifTag.software(exifSoftwareName),
        MomentoBoothExifTag.createDate(DateTime.now()),
      ],
      operationsBeforeEncoding: const [],
    );

    await storePhotoSafe('liveview.jpg', jpegData);

    return PhotoCapture(
      data: jpegData,
      filename: 'liveview.jpg',
    );
  }
  
  @override
  Future<void> clearPreviousEvents() async {}

}
