import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/transition_page.dart';

class CustomRouteData extends GoRouteData {

  final LocalKey? key;
  final bool enableTransitionIn;
  final bool enableTransitionOut;
  final bool opaque;
  final bool barrierDismissible;

  const CustomRouteData({
    this.key,
    this.enableTransitionIn = true,
    this.enableTransitionOut = true,
    this.opaque = true,
    this.barrierDismissible = false,
  });

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return TransitionPage.fromSettings(
      key: key,
      child: build(context, state),
      enableTransitionIn: enableTransitionIn,
      enableTransitionOut: enableTransitionOut,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
    );
  }

}
