import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/capture_screen/capture_screen_controller.dart';
import 'package:momento_booth/views/capture_screen/capture_screen_view_model.dart';
import 'package:momento_booth/views/custom_widgets/capture_counter.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view_background.dart';

class CaptureScreenView extends ScreenViewBase<CaptureScreenViewModel, CaptureScreenController> {

  const CaptureScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Is this very pretty? No. But it works 😅
        FittedBox(
          child: Transform.translate(
            offset: Offset(3000, 0),
            child: SizedBox(
              height: 1000,
              child: PhotoCollage(
                key: viewModel.collageKey,
                singleMode: true,
                aspectRatio: 1/viewModel.collageAspectRatio,
                decodeCallback: viewModel.collageReady,
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getReadyText,
            Flexible(child: Container(
              padding: EdgeInsets.all(40.0),
              constraints: BoxConstraints(maxWidth: 600, maxHeight: 600),
              child: Observer(builder: (_) {
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 50),
                  opacity: viewModel.showCounter ? 1.0 : 0.0,
                  child: CaptureCounter(
                    onCounterFinished: viewModel.onCounterFinished,
                    counterStart: viewModel.counterStart,),
                );
              })
            )),
          ],
        ),
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
                    RotateAnimatedText("Get Ready!", textStyle: theme.titleStyle, duration: Duration(milliseconds: 1000)),
                    RotateAnimatedText("Look at 📷", textStyle: theme.titleStyle, duration: Duration(milliseconds: 1000)),
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
        child: ColoredBox(color: Color(0xFFFFFFFF)),
      );
    });
  }

}
