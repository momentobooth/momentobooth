import 'dart:typed_data';

abstract class CaptureMethod {
  Future<Uint8List> captureAndGetPhoto();
  void capture();
  Future<Uint8List> getPhoto();
}