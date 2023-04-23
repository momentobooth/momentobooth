part of 'main.dart';

List<GoRoute> rootRoutes = [
  _startRoute,
  _chooseCaptureModeRoute,
  _captureRoute,
  _multiCaptureRoute,
  _collageMakerRoute,
  _shareRoute,
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

GoRoute _multiCaptureRoute = GoRoute(
  path: MultiCaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: UniqueKey(),
      child: MultiCaptureScreen(),
    );
  },
);

GoRoute _collageMakerRoute = GoRoute(
  path: CollageMakerScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: CollageMakerScreen(),
    );
  },
);

GoRoute _shareRoute = GoRoute(
  path: ShareScreen.defaultRoute,
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: ShareScreen(),
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
