import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/extensions/build_context_extension.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';

class CaptureCounter extends StatelessWidget {
  final VoidCallback onCounterFinished;
  final int counterStart;
  const CaptureCounter({super.key, required this.onCounterFinished, required this.counterStart});

  RotateAnimatedText _getCounterAnimatedText(String text, MomentoBoothThemeData theme) {
    TextStyle textStyle = theme.captureCounterTextStyle;
    return RotateAnimatedText(
      text,
      textStyle: textStyle,
      duration: const Duration(seconds: 1),
      transitionHeight: (textStyle.fontSize ?? 0) * 10 / 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = context.theme;

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
              onFinished: onCounterFinished,
              animatedTexts: [
                for (int i = counterStart; i > 0; i--)
                  _getCounterAnimatedText(i.toString(), theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

}