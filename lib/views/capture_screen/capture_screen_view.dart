import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/capture_counter.dart';

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
