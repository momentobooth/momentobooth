import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';

enum _Type { memory, file }

class ImageWithLoaderFallback extends StatelessWidget {

  final Uint8List? bytes;
  final File? file;
  final BoxFit? fit;
  final VoidCallback? decodeCallback;
  final _Type _type;

  const ImageWithLoaderFallback.memory(this.bytes, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.memory,
        file = null;

  const ImageWithLoaderFallback.file(this.file, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.file,
        bytes = null;

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (frame == null) {
      return const Center(child: ProgressRing());
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    Image img = _type == _Type.memory ?
      Image.memory(
        bytes!,
        frameBuilder: _frameBuilder,
        fit: fit,
      ) :
      Image.file(
        file!,
        frameBuilder: _frameBuilder,
        fit: fit,
      );

    // Listen to decode status
    img.image
        .resolve(ImageConfiguration.empty)
        .addListener(ImageStreamListener((image, synchronousCall) => decodeCallback?.call()));

    return img;
  }

}
