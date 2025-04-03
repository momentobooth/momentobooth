import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

final class PhotoBoothDialogPage<T> extends CustomRoute<T> {

  static const defaultTransitionDuration = Duration(milliseconds: 800);

  static CurvedAnimation _fadeAndScaleAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.elasticInOut,
      reverseCurve: Curves.easeInOutBack,
    );
  }

  static CurvedAnimation _blurAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeOutQuint,
      reverseCurve: Curves.easeInExpo,
    );
  }

  PhotoBoothDialogPage({
    required super.page,
    super.children,
    super.initial,
    super.barrierDismissible = false,
  }) : super(
          opaque: false,
          durationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          reverseDurationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            double blur = _blurAnimation(animation).value * 5;
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_fadeAndScaleAnimation(animation)),
                child: ScaleTransition(
                  scale: Tween<double>(begin: animation.status == AnimationStatus.reverse ? 0.9 : 0.0, end: 1.0).animate(_fadeAndScaleAnimation(animation)),
                  filterQuality: getIt<SettingsManager>().settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                  child: child,
                ),
              ),
            );
          },
        );

  // @override
  // Route<T> createRoute([BuildContext? _]) => RawDialogRoute<T>(
  //       settings: this,
  //       barrierColor: barrierColor,
  //       barrierDismissible: barrierDismissible,
  //       barrierLabel: barrierLabel,
  //       pageBuilder: (context, animation, secondaryAnimation) => child,
  //       transitionBuilder: transitionsBuilder,
  //       transitionDuration: transitionDuration,
  //     );

}
