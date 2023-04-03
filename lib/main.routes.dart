part of 'main.dart';

List<GoRoute> rootRoutes = [
  _startRoute,
  _chooseCaptureModeRoute,
  _captureRoute,
  _settingsRoute,
];

GoRoute _startRoute = GoRoute(
  path: StartScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: StartScreen(),
    );
  },
);

GoRoute _chooseCaptureModeRoute = GoRoute(
  path: ChooseCaptureModeScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: ChooseCaptureModeScreen(),
    );
  },
);

GoRoute _captureRoute = GoRoute(
  path: CaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: CaptureScreen(),
    );
  },
);

GoRoute _settingsRoute = GoRoute(
  path: SettingsScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: SettingsScreen(),
    );
  },
);
