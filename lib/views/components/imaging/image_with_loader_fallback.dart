import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/components/imaging/rotate_flip_crop.dart';

class ImageWithLoaderFallback extends StatefulWidget {

  final ImageProvider provider;
  final bool applyRotateFlipCrop;

  final int? cacheWidth;
  final int? cacheHeight;

  final BoxFit? fit;
  final VoidCallback? onImageDecoded;

  const ImageWithLoaderFallback(this.provider, {super.key, this.applyRotateFlipCrop = false, this.fit, this.onImageDecoded, this.cacheWidth, this.cacheHeight});

  ImageWithLoaderFallback.memory(Uint8List data, {super.key, this.applyRotateFlipCrop = false, this.fit, this.onImageDecoded, this.cacheWidth, this.cacheHeight}) : provider = MemoryImage(data);

  ImageWithLoaderFallback.file(File file, {super.key, this.applyRotateFlipCrop = false, this.fit, this.onImageDecoded, this.cacheWidth, this.cacheHeight}) : provider = FileImage(file);

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
    _imageWidget = Image(
      image: ResizeImage.resizeIfNeeded(
        widget.cacheWidth,
        widget.cacheHeight,
        widget.provider,
      ),
      fit: widget.fit,
      frameBuilder: _frameBuilder,
    );

    _listener = ImageStreamListener((image, synchronousCall) => widget.onImageDecoded?.call());
    _imageStream = _imageWidget.image.resolve(ImageConfiguration.empty);
    _imageStream.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant ImageWithLoaderFallback oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.provider != oldWidget.provider) {
      _imageStream.removeListener(_listener);
      _initializeFromWidget();
    }
  }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (frame == null) {
      return const Center(child: ProgressRing());
    } else if (widget.applyRotateFlipCrop) {
      return RotateFlipCrop(
        rotate: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate,
        flip: getIt<SettingsManager>().settings.hardware.captureFlip,
        aspectRatio: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio,
        child: child,
      );
    } else {
      return child;
    }
  }

  @override
  Widget build(BuildContext context) => _imageWidget;

  @override
  void dispose() {
    _imageStream.removeListener(_listener);
    super.dispose();
  }

}
