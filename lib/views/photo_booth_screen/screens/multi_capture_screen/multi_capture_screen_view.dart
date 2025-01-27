import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/live_view.dart';
import 'package:momento_booth/views/components/imaging/photo_container.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_view_model.dart';

class MultiCaptureScreenView extends ScreenViewBase<MultiCaptureScreenViewModel, MultiCaptureScreenController> {

  const MultiCaptureScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
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
                aspectRatio: viewModel.aspectRatio,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _liveViewWithCounter,
                    Observer(builder: (_) {
                      if (viewModel.showSpinner) {
                        return Center(child: LoadingDialog(title: localizations.captureScreenLoadingPhoto));
                      }
                      return const SizedBox();
                    }),
                  ],
                ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AutoSizeText(
            localizations.multiCaptureScreenPhotoCounter(viewModel.photoNumber, viewModel.maxPhotos),
            style: theme.titleStyle,
            maxLines: 1,
          ),
        ),
        for (int i = 0; i < getIt<PhotosManager>().photos.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AspectRatio(
                aspectRatio: viewModel.aspectRatio,
                child: PhotoContainer.memory(getIt<PhotosManager>().photos[i].data),
              ),
            ),
          ),
        for (int i = getIt<PhotosManager>().photos.length; i < 4; i++)
          Expanded(child: _photoPlaceholder),
      ],
    );
  }

  Widget get _liveViewWithCounter {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        const LiveView(fit: BoxFit.contain, blur: false),
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
        aspectRatio: viewModel.aspectRatio,
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
            RotateAnimatedText(localizations.multiCaptureScreenGetReady, textStyle: theme.titleStyle, duration: const Duration(milliseconds: 1000)),
            RotateAnimatedText(localizations.multiCaptureScreenLookAtCamera, textStyle: theme.titleStyle, duration: const Duration(milliseconds: 1000)),
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
