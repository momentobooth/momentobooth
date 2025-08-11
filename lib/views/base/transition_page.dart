import 'package:flutter/widgets.dart' hide WidgetBuilder;
import 'package:go_router/go_router.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/components/transitions/fade_and_scale_transition.dart';
import 'package:momento_booth/views/components/transitions/fade_and_slide_transition.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

final class TransitionPage extends CustomTransitionPage<void> {

  static const defaultTransitionDuration = Duration(milliseconds: 500);

  static CurvedAnimation _curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInExpo,
    );
  }

  factory TransitionPage.fromSettings({
    required ValueKey<String> key,
    required BuildContext context,
    required String name,
    required Widget child,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
    bool opaque = true,
    bool barrierDismissible = false,
  }) {
    WidgetBuilder? builder = context.maybeTheme?.screenWrappers[key.value];
    if (builder != null) {
      child = builder(context, child);
    }

    return switch (getIt<SettingsManager>().settings.ui.screenTransitionAnimation) {
      ScreenTransitionAnimation.none => TransitionPage._none(key: key, name: name, child: child, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndScale => TransitionPage._fadeAndScale(key: key, name: name, child: child, enableTransitionIn: enableTransitionIn, enableTransitionOut: enableTransitionOut, opaque: opaque, barrierDismissible: barrierDismissible),
      ScreenTransitionAnimation.fadeAndSlide => TransitionPage._fadeAndSlide(key: key, name: name, child: child, enableTransitionIn: enableTransitionIn, enableTransitionOut: enableTransitionOut, opaque: opaque, barrierDismissible: barrierDismissible),
    };
  }

  TransitionPage._none({
    required super.key,
    required super.name,
    required super.child,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );

  TransitionPage._fadeAndScale({
    required super.key,
    required super.name,
    required super.child,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionDuration,
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
    required super.key,
    required super.name,
    required super.child,
    bool enableTransitionIn = true,
    bool enableTransitionOut = true,
    super.opaque = true,
    super.barrierDismissible = false,
  }) : super(
          transitionDuration: defaultTransitionDuration,
          reverseTransitionDuration: defaultTransitionDuration,
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

  @override
  Route<void> createRoute(BuildContext context) {
    // We assume a transparent screen to be a dialog here.
    return opaque ? super.createRoute(context) : RawDialogRoute<void>(
      barrierDismissible: barrierDismissible,
      transitionDuration: transitionDuration,
      settings: this,
      pageBuilder: (context, _, _) => child,
      transitionBuilder: transitionsBuilder,
      barrierColor: null,
    );
  }

}
