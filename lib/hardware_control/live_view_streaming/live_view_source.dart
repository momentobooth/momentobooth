import 'package:momento_booth/rust_bridge/library_api.generated.dart';

abstract class LiveViewSource {

  String get id;
  String get friendlyName;

  Future<void> openStream({
    required int texturePtrMain,
    required int texturePtrBlur,
    required List<ImageOperation> operations,
  });

  Future<void> setOperations(List<ImageOperation> operations);

  Future<RawImage?> getLastFrame();

  Future<CameraState?> getCameraState();

  Future<void> dispose() async {}

}
