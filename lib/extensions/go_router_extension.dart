import 'package:go_router/go_router.dart';

extension GoRouterExtension on GoRouter {

  String get currentLocation {
    final RouteMatch? lastMatch = routerDelegate.currentConfiguration.lastOrNull;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

}
