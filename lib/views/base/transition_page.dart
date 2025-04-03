import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/components/transitions/fade_and_scale_transition.dart';
import 'package:momento_booth/views/components/transitions/fade_and_slide_transition.dart';

final class TransitionPage<T> extends CustomRoute<T> {

  static const defaultTransitionDuration = Duration(milliseconds: 500);

  static CurvedAnimation _curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInExpo,
    );
  }

  factory TransitionPage.fromSettings({
    required PageInfo page,
    bool initial = false,
    List<AutoRoute>? children,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
    bool opaque = true,
    bool barrierDismissible = false,
  }) {
    return switch (getIt<SettingsManager>().settings.ui.screenTransitionAnimation) {
      ScreenTransitionAnimation.none => TransitionPage._none(page: page, initial: initial, children: children, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndScale => TransitionPage._fadeAndScale(page: page, initial: initial, children: children, enableTransitionIn: enableTransitionIn, enableTransitionOut: enableTransitionOut, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndSlide => TransitionPage._fadeAndSlide(page: page, initial: initial, children: children, enableTransitionIn: enableTransitionIn, enableTransitionOut: enableTransitionOut, opaque: opaque, barrierDismissible: barrierDismissible),
    };
  }

  TransitionPage._none({
    required super.page,
    super.children,
    super.initial,
    super.barrierDismissible = false,
    super.opaque = true,
  }) : super(
          durationInMilliseconds: 0,
          reverseDurationInMilliseconds: 0,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );

  TransitionPage._fadeAndScale({
    required super.page,
    super.children,
    super.initial,
    super.barrierDismissible = false,
    super.opaque = true,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
  }) : super(
          durationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          reverseDurationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeAndScaleTransition(
              enableTransitionIn: enableTransitionIn,
              enableTransitionOut: enableTransitionOut,
              animation: _curvedAnimation(animation),
              secondaryAnimation: _curvedAnimation(secondaryAnimation),
              child: child,
            );
          },
        );

  TransitionPage._fadeAndSlide({
    required super.page,
    super.children,
    super.initial,
    super.barrierDismissible = false,
    super.opaque = true,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
  }) : super(
          durationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          reverseDurationInMilliseconds: defaultTransitionDuration.inMilliseconds,
          customRouteBuilder: !opaque ? _createDialogRoute : null,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeAndSlideTransition(
              enableTransitionIn: enableTransitionIn,
              enableTransitionOut: enableTransitionOut,
              animation: _curvedAnimation(animation),
              secondaryAnimation: _curvedAnimation(secondaryAnimation),
              child: child,
            );
          },
        );

  static Route<TReturn> _createDialogRoute<TReturn>(BuildContext context, Widget child, AutoRoutePage<TReturn> page) {
    // We assume a transparent screen to be a dialog here.
    return RawDialogRoute<TReturn>(
      barrierDismissible: true,
      transitionDuration: defaultTransitionDuration,
      pageBuilder: (context, _, _) => child,
      //transitionBuilder: transitionsBuilder,
      barrierColor: null,
    );
  }

}
