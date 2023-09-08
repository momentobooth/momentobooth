import 'dart:typed_data';

abstract class PhotoCaptureMethod {

  Duration get captureDelay;

  Future<void> clearPreviousEvents();

  Future<Uint8List> captureAndGetPhoto();

}
