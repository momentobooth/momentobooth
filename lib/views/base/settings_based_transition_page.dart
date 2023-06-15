import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';

final class SettingsBasedTransitionPage extends CustomTransitionPage<void> {

  static const defaultTransitionDuration = Duration(milliseconds: 500);

  static CurvedAnimation _curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInExpo,
    );
  }

  factory SettingsBasedTransitionPage.fromSettings({
    required LocalKey key,
    required Widget child,
    bool opaque = true,
    bool barrierDismissible = false,
  }) {
    return switch (SettingsManager.instance.settings.ui.screenTransitionAnimation) {
      ScreenTransitionAnimation.none => SettingsBasedTransitionPage._none(key: key, child: child, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndScale => SettingsBasedTransitionPage._fadeAndScale(key: key, child: child, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndSlide => SettingsBasedTransitionPage._fadeAndSlide(key: key, child: child, opaque: opaque, barrierDismissible: barrierDismissible),
    };
  }

  SettingsBasedTransitionPage._none({
    required super.key,
    required super.child,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );

  SettingsBasedTransitionPage._fadeAndScale({
    required super.key,
    required super.child,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation(animation)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(_curvedAnimation(animation)),
                filterQuality: SettingsManager.instance.settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnimation(secondaryAnimation)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(_curvedAnimation(secondaryAnimation)),
                    filterQuality: SettingsManager.instance.settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

  SettingsBasedTransitionPage._fadeAndSlide({
    required LocalKey super.key,
    required super.child,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation(animation)),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(_curvedAnimation(animation)),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnimation(secondaryAnimation)),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0)).animate(_curvedAnimation(secondaryAnimation)),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

}
