import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/transition_page.dart';

class CustomShellRouteData extends ShellRouteData {

  final bool enableTransitionIn;
  final bool enableTransitionOut;
  final bool opaque;
  final bool barrierDismissible;

  const CustomShellRouteData({
    this.enableTransitionIn = true,
    this.enableTransitionOut = true,
    this.opaque = true,
    this.barrierDismissible = false,
  });

  @override
  Page<void> pageBuilder(BuildContext context, GoRouterState state, Widget navigator) {
    return TransitionPage.fromSettings(
      child: builder(context, state, navigator),
      enableTransitionIn: enableTransitionIn,
      enableTransitionOut: enableTransitionOut,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
    );
  }

  // @override
  // Page<void> buildPage(BuildContext context, GoRouterState state) {
  //   return TransitionPage.fromSettings(
  //     child: build(context, state),
  //     enableTransitionIn: enableTransitionIn,
  //     enableTransitionOut: enableTransitionOut,
  //     opaque: opaque,
  //     barrierDismissible: barrierDismissible,
  //   );
  // }

}
