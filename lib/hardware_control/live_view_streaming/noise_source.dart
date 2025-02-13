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

  late int _handleId;

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
  Future<CameraState?> getCameraState() async => CameraState(
        isStreaming: true,
        validFrameCount: 1,
        errorFrameCount: 0,
        duplicateFrameCount: 0,
        lastFrameWasValid: true,
        frameWidth: 1280,
        frameHeight: 720,
      );

  @override
  Future<void> dispose() => noiseClose(handleId: _handleId);

}
