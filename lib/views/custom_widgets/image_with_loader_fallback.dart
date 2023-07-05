import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';

enum _Type {
  memory(),
  file(),
}

void baseCallback() {}

class ImageWithLoaderFallback extends StatelessWidget {

  late final Uint8List? bytes;
  late final File? file;
  final BoxFit? fit;
  late final _Type _type;
  // var imageDecoded = false;
  final VoidCallback decodeCallback;

  ImageWithLoaderFallback.memory(this.bytes, {super.key, this.fit, this.decodeCallback = baseCallback,}) { _type = _Type.memory; }
  ImageWithLoaderFallback.file(this.file, {super.key, this.fit, this.decodeCallback = baseCallback,}) { _type = _Type.file; }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (frame == null) {
      return const Center(child: ProgressRing());
    }
    return child;
  }
  

  @override
  Widget build(BuildContext context) {
    var img = _type == _Type.memory ?
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
    img.image
    .resolve(ImageConfiguration.empty)
    .addListener(ImageStreamListener((image, synchronousCall) {
      // if (imageDecoded) return;
      // imageDecoded = true;
      decodeCallback();
    }));

    return img;
  }

}
