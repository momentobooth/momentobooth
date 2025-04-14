import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen_view_model.dart';

class CaptureScreenView extends ScreenViewBase<CaptureScreenViewModel, CaptureScreenController> {

  const CaptureScreenView({
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
        // This widget is just here for the purpose of rendering the collage to a bitmap
        PhotoCollage(
          key: viewModel.collageKey,
          singleMode: true,
          aspectRatio: 1/viewModel.collageAspectRatio,
          padding: viewModel.collagePadding,
          decodeCallback: viewModel.collageReady,
        ),
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
                })
              ),
            ),
          ],
        ),
        Observer(
          builder: (_) {
          if (viewModel.showSpinner) {
            return Center(child: LoadingDialog(title: localizations.captureScreenLoadingPhoto));
          }
          return const SizedBox();
        }),
        _flashAnimation,
      ],
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
            RotateAnimatedText(localizations.captureScreenGetReady, textStyle: theme.titleTheme.style, duration: const Duration(milliseconds: 1000)),
            RotateAnimatedText(localizations.captureScreenLookAtCamera, textStyle: theme.titleTheme.style, duration: const Duration(milliseconds: 1000)),
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
