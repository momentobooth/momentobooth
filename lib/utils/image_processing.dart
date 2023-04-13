import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class AppImage {

  img.Image _image;

  // ////////////// //
  // Initialization //
  // ////////////// //

  AppImage._(this._image);

  AppImage.fromRawRgbaData(Uint8List rawData, int width, int height)
      : _image = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rawData.buffer,
          order: img.ChannelOrder.rgba,
        );

  static Future<AppImage> fromEncodedFile(String path) async {
    img.Image? image = await img.decodeImageFile(path);
    if (image == null) {
      throw "Could not find suitable decoder for image";
    }
    return AppImage._(image);
  }

  // ////////// //
  // Operations //
  // ////////// //

  void cropToAspectRatio(double aspectRatio) {
    var currentAspectRatio = _image.width / _image.height;
    late int x, y, width, height;

    if (currentAspectRatio > aspectRatio) {
      // Cut left and right sides
      width = (_image.height * aspectRatio).round();
      height = _image.height;
    } else {
      // Cut top and bottom sides
      width = _image.width;
      height = (_image.width / aspectRatio).round();
    }

    x = ((_image.width - width) / 2).round();
    y = ((_image.height - height) / 2).round();

    _image = img.copyCrop(_image, x: x, y: y, width: width, height: height);
  }

  // ////// //
  // Export //
  // ////// //

  Future<ui.Image> toRawDartImage() async {
    Uint8List? rawData = _image.data?.toUint8List();
    if (rawData == null) {
      throw "Could not get raw image bytes";
    }

    ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(rawData);
    ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(buffer, width: _image.width, height: _image.height, pixelFormat: ui.PixelFormat.rgba8888);
    ui.Codec x = await descriptor.instantiateCodec();
    ui.FrameInfo y = await x.getNextFrame();
    return y.image;
  }

}
