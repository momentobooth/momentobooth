import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

class FadeAndScaleTransition extends StatelessWidget {

  final bool enableTransitionIn;
  final bool enableTransitionOut;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const FadeAndScaleTransition({super.key, required this.enableTransitionIn, required this.enableTransitionOut, required this.animation, required this.secondaryAnimation, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget transitionOut =
        enableTransitionOut
            ? FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.3).animate(secondaryAnimation),
                filterQuality: getIt<SettingsManager>().settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                child: child,
              ),
            )
            : child;

    Widget transitionIn =
        enableTransitionIn
            ? FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                filterQuality: getIt<SettingsManager>().settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                child: transitionOut,
              ),
            )
            : transitionOut;

    return transitionIn;
  }

}
