import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';

class CaptureScreenView extends ScreenViewBase<CaptureScreenViewModel, CaptureScreenController> {

  const CaptureScreenView({
    super.key,
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
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Center(
                child: AutoSizeText(
                  "Get Ready!",
                  style: theme.titleStyle,
                  maxLines: 1,
                ),
              ),
            ),
            Expanded(
              child: AspectRatio(
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
                        animatedTexts: [
                          _getCounterAnimatedText('5'),
                          _getCounterAnimatedText('4'),
                          _getCounterAnimatedText('3'),
                          _getCounterAnimatedText('2'),
                          _getCounterAnimatedText('1'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: const SizedBox(),
            ),
          ],
        ),
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

}
