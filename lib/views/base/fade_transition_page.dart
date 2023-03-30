import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage extends CustomTransitionPage<void> {

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeIn);

  /// Creates a [FadeTransitionPage].
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(_curveTween),
              child: child,
            );
          },
        );

}
