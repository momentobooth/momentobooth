import 'package:momento_booth/src/rust/models/image_operations.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';

abstract class LiveViewSource {

  String get id;
  String get friendlyName;

  Future<void> openStream({
    required BigInt texturePtr,
  });

  Future<void> setOperations(List<ImageOperation> operations);

  Future<RawImage?> getLastFrame();

  Future<CameraState?> getCameraState();

  Future<void> dispose() async {}

}
