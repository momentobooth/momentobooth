import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NoiseSource extends LiveViewSource {

  late int _handleId;

  NoiseSource() : super(id: '', friendlyName: '');

  @override
  Future<void> openStream({required int texturePtr}) async => _handleId = await rustLibraryApi.noiseOpen(texturePtr: texturePtr);

  @override
  Future<RawImage> getLastFrame() => rustLibraryApi.noiseGetFrame();

  @override
  Future<CameraState?> getCameraState() async => null;

  @override
  Future<void> dispose() => rustLibraryApi.noiseClose(handleId: _handleId);

}
