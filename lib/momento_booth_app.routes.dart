part of 'momento_booth_app.dart';

List<RouteBase> _rootRoutes = [
  _onboardingRoute,
  _notAvailableRoute,
  _photoBoothShellRoute,
];

GoRoute _onboardingRoute = GoRoute(
  path: OnboardingScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      name: (OnboardingScreen).toString(),
      context: context,
      child: const OnboardingScreen(),
    );
  },
);

GoRoute _notAvailableRoute = GoRoute(
  path: NotAvailableScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      child: const NotAvailableScreen(),
    );
  },
);

ShellRoute _photoBoothShellRoute = ShellRoute(
  pageBuilder: (context, state, child) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      name: (PhotoBooth).toString(),
      context: context,
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
    return TransitionPage.fromSettings(key: state.pageKey, name: (StartScreen).toString(), context: context, child: const StartScreen());
  },
);

GoRoute _chooseCaptureModeRoute = GoRoute(
  path: ChooseCaptureModeScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (ChooseCaptureModeScreen).toString(), context: context, child: const ChooseCaptureModeScreen());
  },
);

GoRoute _captureRoute = GoRoute(
  path: SingleCaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (SingleCaptureScreen).toString(), context: context, child: const SingleCaptureScreen());
  },
);

GoRoute _multiCaptureRoute = GoRoute(
  path: MultiCaptureScreen.defaultRoute,
  pageBuilder: (context, state) {
    // Here we use state.uri because of the query param `n`.
    return TransitionPage.fromSettings(key: ValueKey(state.uri.toString()), name: (MultiCaptureScreen).toString(), context: context, child: const MultiCaptureScreen());
  },
);

GoRoute _collageMakerRoute = GoRoute(
  path: CollageMakerScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (CollageMakerScreen).toString(), context: context, child: const CollageMakerScreen());
  },
);

GoRoute _shareRoute = GoRoute(
  path: ShareScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (ShareScreen).toString(), context: context, child: const ShareScreen());
  },
);

GoRoute _galleryRoute = GoRoute(
  path: GalleryScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (GalleryScreen).toString(), context: context, child: const GalleryScreen());
  },
);

GoRoute _photoDetailsRoute = GoRoute(
  path: "${PhotoDetailsScreen.defaultRoute}/:pid",
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(
      key: state.pageKey,
      name: (PhotoDetailsScreen).toString(),
      context: context,
      opaque: true,
      barrierDismissible: true,
      child: PhotoDetailsScreen(photoId: state.pathParameters['pid']!),
    );
  },
);

GoRoute _manualCollageRoute = GoRoute(
  path: ManualCollageScreen.defaultRoute,
  pageBuilder: (context, state) {
    return TransitionPage.fromSettings(key: state.pageKey, name: (ManualCollageScreen).toString(), context: context, child: const ManualCollageScreen());
  },
);
