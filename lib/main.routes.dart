part of 'main.dart';

List<GoRoute> rootRoutes = [
  _startRoute,
  _chooseCaptureModeRoute,
  _captureRoute,
];

GoRoute _startRoute = GoRoute(
  path: '/',
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: StartScreen(),
    );
  },
);

GoRoute _chooseCaptureModeRoute = GoRoute(
  path: '/choose_capture_mode',
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: ChooseCaptureModeScreen(),
    );
  },
);

GoRoute _captureRoute = GoRoute(
  path: '/capture',
  pageBuilder: (context, state) {
    return FadeTransitionPage(
      key: state.pageKey,
      child: CaptureScreen(),
    );
  },
);
