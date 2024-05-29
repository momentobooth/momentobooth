import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/src/rust/api/noise.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

class NoiseSource extends LiveViewSource {

  @override
  final String id = '';

  @override
  final String friendlyName = '';

  late BigInt _handleId;

  NoiseSource();

  @override
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [], // TODO: Implement
  }) async {
    _handleId = await noiseOpen(
      texturePtr: texturePtr,
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) async {}

  @override
  Future<RawImage> getLastFrame() => noiseGetFrame();

  @override
  Future<CameraState?> getCameraState() async => null;

  @override
  Future<void> dispose() => noiseClose(handleId: _handleId);

}
