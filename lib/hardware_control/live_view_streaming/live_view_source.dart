import 'package:momento_booth/rust_bridge/library_api.generated.dart';

abstract class LiveViewSource {

  final String id;
  final String friendlyName;

  LiveViewSource({required this.id, required this.friendlyName});

  Future<void> openStream({required int texturePtr});

  Future<RawImage?> getLastFrame();

  Future<CameraState?> getCameraState();

  Future<void> dispose() async {}

}
