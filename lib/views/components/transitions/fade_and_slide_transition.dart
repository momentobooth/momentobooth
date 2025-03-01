import 'package:flutter/widgets.dart';

class FadeAndSlideTransition extends StatelessWidget {

  final bool enableTransitionIn;
  final bool enableTransitionOut;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const FadeAndSlideTransition({super.key, required this.enableTransitionIn, required this.enableTransitionOut, required this.animation, required this.secondaryAnimation, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget transitionOut =
        enableTransitionOut
            ? FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation),
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0)).animate(secondaryAnimation),
                child: child,
              ),
            )
            : child;

    Widget transitionIn =
        enableTransitionIn
            ? FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(animation),
                child: transitionOut,
              ),
            )
            : transitionOut;

    return transitionIn;
  }

}
