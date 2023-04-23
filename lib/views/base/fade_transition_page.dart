import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage extends CustomTransitionPage<void> {

  /// Creates a [FadeTransitionPage].
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(secondaryAnimation),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

}
