import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

abstract class LiveViewSource {

  String get id;
  String get friendlyName;

  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [],
  });

  Future<void> setOperations(List<ImageOperation> operations);

  Future<RawImage?> getLastFrame();

  Future<CameraState?> getCameraState();

  Future<void> dispose() async {}

}
