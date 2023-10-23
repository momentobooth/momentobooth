part of 'shell.dart';

List<GoRoute> _rootRoutes = [
  _photoBoothRoute,
  _settingsRoute,
];

GoRoute _photoBoothRoute = GoRoute(
  path: "/photo_booth",
  pageBuilder: (context, state) {
    return SettingsBasedTransitionPage.fromSettings(
      key: state.pageKey,
      child: const PhotoBooth(),
    );
  },
);

GoRoute _settingsRoute = GoRoute(
  path: "/settings",
  pageBuilder: (context, state) {
    return SettingsBasedTransitionPage.fromSettings(
      key: state.pageKey,
      child: const FullScreenPopup(
        child: PhotoBooth(),
      ),
    );
  },
);
