import 'dart:typed_data';

abstract class PhotoCaptureMethod {

  Duration get captureDelay;

  Future<Uint8List> captureAndGetPhoto();

}
