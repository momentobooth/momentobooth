import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/rotate_flip_crop.dart';

enum _Type { memory, file, asset }

class CaptureViewBox extends StatefulWidget {

  final Uint8List? bytes;
  final File? file;
  final String? assetPath;

  final BoxFit? fit;
  final VoidCallback? decodeCallback;
  final _Type _type;

  const CaptureViewBox.memory(this.bytes, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.memory,
        file = null,
        assetPath = null;

  const CaptureViewBox.file(this.file, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.file,
        bytes = null,
        assetPath = null;

  const CaptureViewBox.asset(this.assetPath, {super.key, this.fit, this.decodeCallback})
      : _type = _Type.asset,
        bytes = null,
        file = null;

  @override
  State<CaptureViewBox> createState() => _CaptureViewBoxState();

}

class _CaptureViewBoxState extends State<CaptureViewBox> {

  bool _isImageDecoded = false;

  void _imageDecoded() {
    widget.decodeCallback?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isImageDecoded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageWithLoaderFallback img = switch(widget._type) {
      _Type.memory => ImageWithLoaderFallback.memory(widget.bytes, fit: widget.fit, decodeCallback: _imageDecoded),
      _Type.file => ImageWithLoaderFallback.file(widget.file, fit: widget.fit, decodeCallback: _imageDecoded),
      _Type.asset => ImageWithLoaderFallback.asset(widget.assetPath, fit: widget.fit, decodeCallback: _imageDecoded),
    };

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (!_isImageDecoded)
          const Center(child: ProgressRing()),
        Visibility.maintain(
          visible: _isImageDecoded,
          child: RotateFlipCrop(
            rotate: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate,
            flip: getIt<SettingsManager>().settings.hardware.captureFlip,
            aspectRatio: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio,
            child: img,
          ),
        ),
      ],
    );
  }

}
