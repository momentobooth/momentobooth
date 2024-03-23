import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';

enum _Type { memory, file }

class ImageWithLoaderFallback extends StatefulWidget {

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

  @override
  State<ImageWithLoaderFallback> createState() => _ImageWithLoaderFallbackState();

}

class _ImageWithLoaderFallbackState extends State<ImageWithLoaderFallback> {

  late Image _imageWidget;
  late ImageStream _imageStream;
  late ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _initializeFromWidget();
  }

  void _initializeFromWidget() {
    _imageWidget = widget._type == _Type.memory
        ? Image.memory(
            widget.bytes!,
            frameBuilder: _frameBuilder,
            fit: widget.fit,
          )
        : Image.file(
            widget.file!,
            frameBuilder: _frameBuilder,
            fit: widget.fit,
          );

    _listener = ImageStreamListener((image, synchronousCall) => widget.decodeCallback?.call());
    _imageStream = _imageWidget.image.resolve(ImageConfiguration.empty);
    _imageStream.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant ImageWithLoaderFallback oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.bytes != oldWidget.bytes || widget.file != oldWidget.file) {
      _imageStream.removeListener(_listener);
      _initializeFromWidget();
    }
  }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    return frame != null ? child : const Center(child: ProgressRing());
  }

  @override
  Widget build(BuildContext context) => _imageWidget;

  @override
  void dispose() {
    _imageStream.removeListener(_listener);
    super.dispose();
  }

}
