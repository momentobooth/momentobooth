import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/rotate_flip_crop_container.dart';

enum _Type { memory, file, asset }

class PhotoContainer extends StatelessWidget {

  final Uint8List? bytes;
  final File? file;
  final String? assetPath;

  final BoxFit? fit;
  final VoidCallback? decodeCallback;
  final _Type _type;

  const PhotoContainer.memory(this.bytes, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.memory,
        file = null,
        assetPath = null;

  const PhotoContainer.file(this.file, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.file,
        bytes = null,
        assetPath = null;

  const PhotoContainer.asset(this.assetPath, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.asset,
        bytes = null,
        file = null;

  @override
  Widget build(BuildContext context) {
    ImageWithLoaderFallback img = switch(_type) {
      _Type.memory => ImageWithLoaderFallback.memory(
        bytes,
        fit: fit,
        decodeCallback: decodeCallback,
      ),
      _Type.file => ImageWithLoaderFallback.file(
        file,
        fit: fit,
        decodeCallback: decodeCallback,
      ),
      _Type.asset => ImageWithLoaderFallback.asset(
        assetPath,
        fit: fit,
        decodeCallback: decodeCallback,
      ),
    };

    return RotateFlipCropContainer(
      rotate: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate,
      flip: getIt<SettingsManager>().settings.hardware.captureFlip,
      aspectRatio: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio,
      child: img,
    );
  }

}
