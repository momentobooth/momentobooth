import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';

class ImageWithLoaderFallback extends StatelessWidget {

  final Uint8List bytes;
  final BoxFit? fit;

  const ImageWithLoaderFallback.memory(this.bytes, {super.key, this.fit});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          return Center(child: ProgressRing());
        }
        return child;
      },
      fit: fit,
    );
  }

}
