import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/managers/settings_manager.dart';

final class PhotoBoothDialogPage extends CustomTransitionPage<void> {

  static const defaultTransitionDuration = Duration(milliseconds: 500);

  static CurvedAnimation _curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.elasticInOut,
      reverseCurve: Curves.elasticInOut,
    );
  }

  PhotoBoothDialogPage({
    required super.key,
    required super.child,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation(animation)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation(animation)),
                filterQuality: SettingsManager.instance.settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnimation(secondaryAnimation)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnimation(secondaryAnimation)),
                    filterQuality: SettingsManager.instance.settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

}
