import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage extends CustomTransitionPage<void> {

  static CurvedAnimation _curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInExpo,
    );
  }

  /// Creates a [FadeTransitionPage].
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation(animation)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(_curvedAnimation(animation)),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnimation(secondaryAnimation)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(_curvedAnimation(secondaryAnimation)),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

}
