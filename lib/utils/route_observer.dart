import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/utils/logger.dart';

class GoRouterObserver extends NavigatorObserver with Logger {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      String routeType = page.child.runtimeType.toString();

      logDebug("Route push: $routeType");
      getIt<MqttManager>().publishScreen(routeType);
    } else {
      logDebug("Route push: Unknown (is not a CustomTransitionPage))");
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      String routeType = page.child.runtimeType.toString();

      logDebug("Route pop: $routeType");
      getIt<MqttManager>().publishScreen(routeType);
    } else {
      logDebug("Route pop: Unknown (is not a CustomTransitionPage))");
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (route.settings is CustomTransitionPage) {
      CustomTransitionPage page = route.settings as CustomTransitionPage;
      String routeType = page.child.runtimeType.toString();

      logDebug("Route remove: $routeType");
    } else {
      logDebug("Route remove: Unknown (is not a CustomTransitionPage))");
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    String? newRouteChildName, oldRouteChildName;

    if (newRoute == null) {
      newRouteChildName = "None";
    } else if (newRoute.settings is CustomTransitionPage) {
      CustomTransitionPage page = newRoute.settings as CustomTransitionPage;
      newRouteChildName = page.child.runtimeType.toString();
    }

    if (oldRoute == null) {
      oldRouteChildName = "None";
    } else if (oldRoute.settings is CustomTransitionPage) {
      CustomTransitionPage page = oldRoute.settings as CustomTransitionPage;
      oldRouteChildName = page.child.runtimeType.toString();
    }

    logDebug("Route replaced ${oldRouteChildName ?? 'Unknown (is not a CustomTransitionPage)'} with ${newRouteChildName ?? 'Unknown (is not a CustomTransitionPage)'}");
    if (newRouteChildName != null) getIt<MqttManager>().publishScreen(newRouteChildName);
  }

}
