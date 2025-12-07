import 'package:flutter/widgets.dart';

/// A widget that cycles through a list of texts with a fading animation,
/// while smoothly animating its size to match the current text.
class FadingTextSwitcher extends StatefulWidget {
  final List<String> texts;
  final Duration displayDuration;
  final Duration fadeDuration;
  final TextStyle? style;
  final TextAlign textAlign;

  const FadingTextSwitcher({
    super.key,
    required this.texts,
    this.displayDuration = const Duration(seconds: 2),
    this.fadeDuration = const Duration(milliseconds: 300),
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<FadingTextSwitcher> createState() => _FadingTextSwitcherState();
}

class _FadingTextSwitcherState extends State<FadingTextSwitcher> with TickerProviderStateMixin {
  int index = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(widget.displayDuration, () {
      if (!mounted) return;
      setState(() {
        index = (index + 1) % widget.texts.length;
      });
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.fadeDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: widget.fadeDuration,
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        layoutBuilder: (currentChild, previousChildren) {
          // It's important to use a Stack here to prevent layout jumps when the text size changes
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Text(
          widget.texts[index],
          key: ValueKey(widget.texts[index]),
          style: widget.style,
          textAlign: widget.textAlign,
        ),
      ),
    );
  }
}
