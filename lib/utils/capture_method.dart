import 'dart:typed_data';

abstract class CaptureMethod {
  Duration get captureDelay;
  Future<Uint8List> captureAndGetPhoto();
  void capture();
  Future<Uint8List> getPhoto();
}