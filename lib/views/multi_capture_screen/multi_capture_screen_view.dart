import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view_background.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen_controller.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen_view_model.dart';
import 'package:momento_booth/views/custom_widgets/capture_counter.dart';

class MultiCaptureScreenView extends ScreenViewBase<MultiCaptureScreenViewModel, MultiCaptureScreenController> {
  const MultiCaptureScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              flex: 1,
              child: _photoColumn,
            ),
            Flexible(
              flex: 5,
              child: AspectRatio(
                aspectRatio: 1.5,
                child: _liveViewWithCounter,
              ),
            ),
          ],
        ),
        _flashAnimation,
      ],
    );
  }

  Widget get _photoColumn {
    return Column(
      children: [
        Flexible(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AutoSizeText(
            "Photo ${viewModel.photoNumber}/${viewModel.maxPhotos}",
            style: theme.titleStyle,
            maxLines: 1,
          ),
        )),
        for (int i = 0; i < PhotosManager.instance.photos.length; i++)
          Flexible(
            flex: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: ImageWithLoaderFallback.memory(PhotosManager.instance.photos[i]),
              ),
            ),
          ),
        for (int i = PhotosManager.instance.photos.length; i < 4; i++) Flexible(flex: 0, child: _photoPlaceholder),
      ],
    );
  }

  Widget get _liveViewWithCounter {
    return Stack(
      fit: StackFit.expand,
      children: [
        const LiveView(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getReadyText,
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(40.0),
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                child: Observer(builder: (_) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 50),
                    opacity: viewModel.showCounter ? 1.0 : 0.0,
                    child: CaptureCounter(
                      onCounterFinished: viewModel.onCounterFinished,
                      counterStart: viewModel.counterStart,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _photoPlaceholder {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: theme.captureCounterContainerBorder,
          ),
        ),
      ),
    );
  }

  Widget get _getReadyText {
    return Center(
      child: SizedBox(
        height: 300,
        child: AnimatedTextKit(
          pause: Duration(milliseconds: viewModel.counterStart >= 3 ? 1000 : 0),
          isRepeatingAnimation: false,
          animatedTexts: [
            RotateAnimatedText("Get Ready!", textStyle: theme.titleStyle, duration: const Duration(milliseconds: 1000)),
            RotateAnimatedText("Look at 📷", textStyle: theme.titleStyle, duration: const Duration(milliseconds: 1000)),
          ],
        ),
      ),
    );
  }

  Widget get _flashAnimation {
    return Observer(builder: (_) {
      return AnimatedOpacity(
        opacity: viewModel.opacity,
        duration: viewModel.flashAnimationDuration,
        curve: viewModel.flashAnimationCurve,
        child: const ColoredBox(color: Color(0xFFFFFFFF)),
      );
    });
  }
}
