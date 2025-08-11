import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/utils/logger.dart';

class GoRouterObserver extends NavigatorObserver with Logger {

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    String routeName = route.settings.name ?? 'Unknown';
    logDebug("Route push: $routeName");
    getIt<MqttManager>().publishScreen(routeName);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    String routeName = route.settings.name ?? 'Unknown';
    String previousRouteName = previousRoute == null ? 'None' : previousRoute.settings.name ?? 'Unknown';
    logDebug("Route pop: $routeName, Previous: $previousRouteName");
    getIt<MqttManager>().publishScreen(previousRouteName);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    String routeName = route.settings.name ?? 'Unknown';
    String previousRouteName = previousRoute == null ? 'None' : previousRoute.settings.name ?? 'Unknown';
    logDebug("Route remove: $routeName, Previous: $previousRouteName");
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    String newRouteName = newRoute == null ? 'None' : newRoute.settings.name ?? 'Unknown';
    String oldRouteeName = oldRoute == null ? 'None' : oldRoute.settings.name ?? 'Unknown';

    logDebug("Route replaced $oldRouteeName with $newRouteName");
    getIt<MqttManager>().publishScreen(newRouteName);
  }

}
