part of 'shell.dart';

List<GoRoute> _rootRoutes = [
  _photoBoothRoute,
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
