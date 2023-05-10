import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';

class CaptureCounter extends StatefulWidget {
  final VoidCallback onCounterFinished;
  final int counterStart;

  const CaptureCounter({
    super.key,
    required this.onCounterFinished,
    required this.counterStart,
  });

  @override
  State<CaptureCounter> createState() => CaptureCounterState();
}

class CaptureCounterState extends State<CaptureCounter>
    with SingleTickerProviderStateMixin {

  late final controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.counterStart),
  )..addListener(() {
    setState(() {});
  })..reverse(from: 1);

  static const double borderWidth = 10.0;

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.captureCounterContainerBackground,
              // border: theme.captureCounterContainerBorder,
              borderRadius: theme.captureCounterContainerBorderRadius,
              boxShadow: [theme.captureCounterContainerShadow],
            ),
            child: FittedBox(
              child: DefaultTextStyle(
                style: theme.captureCounterTextStyle,
                child: AnimatedTextKit(
                  pause: Duration.zero,
                  isRepeatingAnimation: false,
                  onFinished: widget.onCounterFinished,
                  animatedTexts: [
                    for (int i = widget.counterStart; i > 0; i--)
                      _getCounterAnimatedText(i.toString(), theme),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(0.5*borderWidth),
            child: CircularProgressIndicator(
              value: controller.value,
              color: Colors.white,
              strokeWidth: borderWidth,
            ),
          ),
        ],
      ),
    );
  }

}