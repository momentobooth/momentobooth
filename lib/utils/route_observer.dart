import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';

class GoRouterObserver extends NavigatorObserver with UiLoggy {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      loggy.debug("Route push: ${page.child}");
      MqttManager.instance.publishScreen('${page.child}');
    } else {
      loggy.debug("Route push: Unknown (could not cast to CustomTransitionPage))");
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      loggy.debug("Route pop: ${page.child}");
      MqttManager.instance.publishScreen('${page.child}');
    } else {
      loggy.debug("Route pop: Unknown (could not cast to CustomTransitionPage))");
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      loggy.debug("Route remove: ${page.child}");
    } else {
      loggy.debug("Route remove: Unknown (could not cast to CustomTransitionPage))");
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    String? newRouteChildName, oldRouteChildName;

    if (newRoute == null) {
      newRouteChildName = "None";
    } else if (newRoute.settings is CustomTransitionPage) {
      CustomTransitionPage page = newRoute.settings as CustomTransitionPage;
      newRouteChildName = page.child.toString();
    }

    if (oldRoute == null) {
      oldRouteChildName = "None";
    } else if (oldRoute.settings is CustomTransitionPage) {
      CustomTransitionPage page = oldRoute.settings as CustomTransitionPage;
      oldRouteChildName = page.child.toString();
    }

    loggy.debug("Route replaced ${oldRouteChildName ?? 'Unknown (could not cast)'} with ${newRouteChildName ?? 'Unknown (could not cast)'}");
    if (newRouteChildName != null) MqttManager.instance.publishScreen(newRouteChildName);
  }

}
