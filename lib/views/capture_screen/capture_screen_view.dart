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
    TextStyle counterStyle = theme.titleStyle;
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
              child: FittedBox(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.captureCounterContainerBackground,
                    border: theme.captureCounterContainerBorder,
                    borderRadius: theme.captureCounterContainerBorderRadius,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      RotateAnimatedText('5'),
                      RotateAnimatedText('4'),
                      RotateAnimatedText('3'),
                      RotateAnimatedText('2'),
                      RotateAnimatedText('1'),
                    ],
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

}
