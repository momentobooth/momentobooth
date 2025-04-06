import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/rotate_flip_crop.dart';

class CaptureViewBox extends StatefulWidget {

  final ImageWithLoaderFallback Function(VoidCallback setImageDecoded) imageBuilder;

  const CaptureViewBox({super.key, required this.imageBuilder});

  @override
  State<CaptureViewBox> createState() => _CaptureViewBoxState();

}

class _CaptureViewBoxState extends State<CaptureViewBox> {

  bool _isImageDecoded = false;

  void _setImageDecoded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isImageDecoded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: widget.imageBuilder(_setImageDecoded),
          ),
        ),
      ],
    );
  }

}
