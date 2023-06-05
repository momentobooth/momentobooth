import 'package:flutter/widgets.dart';

class DelayedWidget extends StatelessWidget {

  final Duration delay;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget child;

  const DelayedWidget({
    super.key,
    required this.delay,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.linear,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done ? 1 : 0,
          duration: animationDuration,
          curve: animationCurve,
          child: child,
        );
      }
    );
  }

}
