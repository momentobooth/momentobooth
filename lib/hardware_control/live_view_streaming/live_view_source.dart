import 'package:momento_booth/src/rust/api/simple.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

abstract class LiveViewSource {

  String get id;
  String get friendlyName;

  Future<void> openStream({
    required int texturePtr,
    List<ImageOperation> operations = const [],
  });

  Future<void> setOperations(List<ImageOperation> operations);

  Future<RawImage?> getLastFrame();

  Future<CameraState?> getCameraState();

  Future<void> dispose() async {}

}
