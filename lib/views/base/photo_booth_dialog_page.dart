import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

final class PhotoBoothDialogPage<T> extends CustomTransitionPage<void> {

  static const defaultTransitionDuration = Duration(milliseconds: 800);
  static const defaultTransitionOutDuration = Duration(milliseconds: 400);

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
    required super.child,
    super.key,
    super.barrierDismissible = false,
  }) : super(
          opaque: false,
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionOutDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            double blur = _blurAnimation(animation).value * 5;
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_fadeAndScaleAnimation(animation)),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(_fadeAndScaleAnimation(animation)),
                  filterQuality: getIt<SettingsManager>().settings.ui.screenTransitionAnimationFilterQuality.toUiFilterQuality(),
                  child: child,
                ),
              ),
            );
          },
        );

  @override
  Route<T> createRoute([BuildContext? _]) => PhotoBoothDialogRoute<T>(
        settings: this,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionBuilder: transitionsBuilder,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
      );

}

class PhotoBoothDialogRoute<T> extends RawDialogRoute<T> {

  @override
  final Duration reverseTransitionDuration;

  PhotoBoothDialogRoute({
    required super.settings,
    required super.barrierColor,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.pageBuilder,
    required super.transitionBuilder,
    required super.transitionDuration,
    required this.reverseTransitionDuration,
  });

}
