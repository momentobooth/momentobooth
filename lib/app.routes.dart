part of 'app.dart';

List<RouteBase> _rootRoutes = [
  _onboardingRoute,
  _photoBoothShellRoute,
];

GoRoute _onboardingRoute = GoRoute(
  path: "/onboarding",
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      child: const OnboardingScreen(),
    );
  },
);

ShellRoute _photoBoothShellRoute = ShellRoute(
  pageBuilder: (context, state, child) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      enableTransitionOut: false,
      child: PhotoBooth(child: child),
    );
  },
  observers: [GoRouterObserver()],
  routes: [
    _startRoute,
    _chooseCaptureModeRoute,
    _captureRoute,
    _multiCaptureRoute,
    _collageMakerRoute,
    _shareRoute,
    _galleryRoute,
    _photoDetailsRoute,
    _manualCollageRoute,
  ],
);

// ////////////////// //
// Photo booth routes //
// ////////////////// //

GoRoute _startRoute = GoRoute(
  path: StartScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const StartScreen());
  },
);

GoRoute _chooseCaptureModeRoute = GoRoute(
  path: ChooseCaptureModeScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const ChooseCaptureModeScreen());
  },
);

GoRoute _captureRoute = GoRoute(
  path: SingleCaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const SingleCaptureScreen());
  },
);

GoRoute _multiCaptureRoute = GoRoute(
  path: MultiCaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    // Here we use state.uri because of the query param `n`.
    return TransitionPage.fromSettings(key: ValueKey(state.uri), child: const MultiCaptureScreen());
  },
);

GoRoute _collageMakerRoute = GoRoute(
  path: CollageMakerScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const CollageMakerScreen());
  },
);

GoRoute _shareRoute = GoRoute(
  path: ShareScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const ShareScreen());
  },
);

GoRoute _galleryRoute = GoRoute(
  path: GalleryScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const GalleryScreen());
  },
);

GoRoute _photoDetailsRoute = GoRoute(
  path: "${PhotoDetailsScreen.defaultRoute}/:pid",
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      opaque: true,
      barrierDismissible: true,
      child: PhotoDetailsScreen(photoId: state.pathParameters['pid']!),
    );
  },
);

GoRoute _manualCollageRoute = GoRoute(
  path: ManualCollageScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, child: const ManualCollageScreen());
  },
);
