import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/rotate_flip_crop_container.dart';

enum _Type { memory, file }

class PhotoContainer extends StatelessWidget {

  final Uint8List? bytes;
  final File? file;
  final BoxFit? fit;
  final VoidCallback? decodeCallback;
  final _Type _type;

  const PhotoContainer.memory(this.bytes, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.memory,
        file = null;

  const PhotoContainer.file(this.file, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.file,
        bytes = null;

  @override
  Widget build(BuildContext context) {
    ImageWithLoaderFallback img = _type == _Type.memory ?
      ImageWithLoaderFallback.memory(
        bytes,
        fit: fit,
        decodeCallback: decodeCallback,
      ) :
      ImageWithLoaderFallback.file(
        file,
        fit: fit,
        decodeCallback: decodeCallback,
      );

    return RotateFlipCropContainer(
      rotate: SettingsManager.instance.settings.hardware.liveViewAndCaptureRotate,
      flip: SettingsManager.instance.settings.hardware.captureFlip,
      aspectRatio: SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio,
      child: img,
    );
  }

}
