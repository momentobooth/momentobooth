import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';

enum _Type {
  memory(),
  file(),
}

class ImageWithLoaderFallback extends StatelessWidget {

  late final Uint8List? bytes;
  late final File? file;
  final BoxFit? fit;
  late final _Type _type;

  ImageWithLoaderFallback.memory(this.bytes, {super.key, this.fit}) { _type = _Type.memory; }
  ImageWithLoaderFallback.file(this.file, {super.key, this.fit}) { _type = _Type.file; }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (frame == null) {
      return const Center(child: ProgressRing());
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (_type == _Type.memory) {
      return Image.memory(
        bytes!,
        frameBuilder: _frameBuilder,
        fit: fit,
      );
    }
    return Image.file(
      file!,
      frameBuilder: _frameBuilder,
      fit: fit,
    );
  }

}
