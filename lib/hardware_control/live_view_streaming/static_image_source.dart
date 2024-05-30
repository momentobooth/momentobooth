import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

class StaticImageSource extends LiveViewSource {

  @override
  final String id = '';

  @override
  final String friendlyName = '';

  late final int _imageWidth, _imageHeight;

  StaticImageSource();

  @override
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [], // TODO: Implement
  }) async {
    RawImage image = await _getPlaceholder();
    _imageWidth = image.width;
    _imageHeight = image.height;

    await staticImageWriteToTexture(
      texturePtr: texturePtr,
      rawImage: image,
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) async {}

  @override
  Future<RawImage> getLastFrame() => _getPlaceholder();

  @override
  Future<CameraState?> getCameraState() async => CameraState(
    isStreaming: true,
    validFrameCount: 1,
    errorFrameCount: 0,
    duplicateFrameCount: 0,
    lastFrameWasValid: true,
    frameWidth: _imageWidth,
    frameHeight: _imageHeight,
  );

  Future<RawImage> _getPlaceholder() async {
    final ByteData data = await rootBundle.load('assets/bitmap/placeholder.png');
    final Image image = await decodeImageFromList(data.buffer.asUint8List());

    return RawImage(
      format: RawImageFormat.rgba,
      width: image.width,
      height: image.height,
      data: (await image.toByteData())!.buffer.asUint8List(),
    );
  }

}
