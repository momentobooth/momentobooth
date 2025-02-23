import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

final class OnboardingWizardPage extends CustomTransitionPage<void> {

  OnboardingWizardPage({required super.child}) : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      );

}
