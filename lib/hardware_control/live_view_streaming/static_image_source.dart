import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class StaticImageSource extends LiveViewSource {

  @override
  final String id = '';

  @override
  final String friendlyName = '';

  StaticImageSource();

  @override
  Future<void> openStream({
    required int texturePtr,
    required List<ImageOperation> operations,
  }) async {
    final ByteData data = await rootBundle.load('assets/bitmap/placeholder.png');
    final Image image = await decodeImageFromList(data.buffer.asUint8List());

    await rustLibraryApi.writeImageToTexture(
      texturePtr: texturePtr,
      rawImage: RawImage(
        format: RawImageFormat.Rgba,
        width: image.width,
        height: image.height,
        data: (await image.toByteData())!.buffer.asUint8List(),
      )
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) async {}

  @override
  Future<RawImage> getLastFrame() => rustLibraryApi.noiseGetFrame();

  @override
  Future<CameraState?> getCameraState() async => null;

}
