import 'dart:typed_data';
import 'dart:ui' as ui;

Future<ui.Image> fromUint8ListRgba(int width, int height, Uint8List rgbaData) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(rgbaData);
    descriptor = ui.ImageDescriptor.raw(buffer, width: width, height: height, pixelFormat: ui.PixelFormat.rgba8888);
    codec = await descriptor.instantiateCodec();
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  } finally {
    buffer?.dispose();
    descriptor?.dispose();
    codec?.dispose();
  }
}
