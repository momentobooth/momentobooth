import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';

class GoRouterObserver extends NavigatorObserver with UiLoggy {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    var routeDynamic = route as dynamic;
    loggy.debug("Route push: ${routeDynamic.settings.child}");
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    var routeDynamic = route as dynamic;
    loggy.debug("Route pop: ${routeDynamic.settings.child}");
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    var routeDynamic = route as dynamic;
    loggy.debug("Route remove: ${routeDynamic.settings.child}");
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    var oldRouteDynamic = oldRoute as dynamic;
    var newRouteDynamic = newRoute as dynamic;
    loggy.debug("Route replaced ${oldRouteDynamic.settings.child} with ${newRouteDynamic.settings.child}");
  }

}
