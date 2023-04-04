import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';

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
        const SampleBackground(),
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
                  child: _counter
                );
              })
            )),
          ],
        ),
        _flashAnimation
      ],
    );
  }

  RotateAnimatedText _getCounterAnimatedText(String text) {
    TextStyle textStyle = theme.captureCounterTextStyle;
    return RotateAnimatedText(
      text,
      textStyle: textStyle,
      duration: const Duration(seconds: 1),
      transitionHeight: (textStyle.fontSize ?? 0) * 10 / 4,
    );
  }

  Widget get _getReadyText {
    return Center(
      child: AutoSizeText(
        "Get Ready!",
        style: theme.titleStyle,
        maxLines: 1,
      ),
    );
  }

  Widget get _counter {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: theme.captureCounterContainerBackground,
          border: theme.captureCounterContainerBorder,
          borderRadius: theme.captureCounterContainerBorderRadius,
          boxShadow: [theme.captureCounterContainerShadow],
        ),
        child: FittedBox(
          child: DefaultTextStyle(
            style: theme.captureCounterTextStyle,
            child: AnimatedTextKit(
              pause: Duration.zero,
              isRepeatingAnimation: false,
              onFinished: viewModel.onCounterFinished,
              animatedTexts: [
                for (int i = viewModel.counterStart; i > 0; i--)
                  _getCounterAnimatedText(i.toString()),
              ],
            ),
          ),
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
