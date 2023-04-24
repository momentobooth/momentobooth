import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage extends CustomTransitionPage<void> {

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeInOutCubicEmphasized);

  /// Creates a [FadeTransitionPage].
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation.drive(_curveTween)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation.drive(_curveTween)),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation.drive(_curveTween)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(secondaryAnimation.drive(_curveTween)),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

}
