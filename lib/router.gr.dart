// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [ChooseCaptureModeScreen]
class ChooseCaptureModeRoute extends PageRouteInfo<void> {
  const ChooseCaptureModeRoute({List<PageRouteInfo>? children})
      : super(
          ChooseCaptureModeRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChooseCaptureModeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChooseCaptureModeScreen();
    },
  );
}

/// generated route for
/// [CollageMakerScreen]
class CollageMakerRoute extends PageRouteInfo<void> {
  const CollageMakerRoute({List<PageRouteInfo>? children})
      : super(
          CollageMakerRoute.name,
          initialChildren: children,
        );

  static const String name = 'CollageMakerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CollageMakerScreen();
    },
  );
}

/// generated route for
/// [GalleryScreen]
class GalleryRoute extends PageRouteInfo<void> {
  const GalleryRoute({List<PageRouteInfo>? children})
      : super(
          GalleryRoute.name,
          initialChildren: children,
        );

  static const String name = 'GalleryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GalleryScreen();
    },
  );
}

/// generated route for
/// [ManualCollageScreen]
class ManualCollageRoute extends PageRouteInfo<void> {
  const ManualCollageRoute({List<PageRouteInfo>? children})
      : super(
          ManualCollageRoute.name,
          initialChildren: children,
        );

  static const String name = 'ManualCollageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ManualCollageScreen();
    },
  );
}

/// generated route for
/// [MultiCaptureScreen]
class MultiCaptureRoute extends PageRouteInfo<void> {
  const MultiCaptureRoute({List<PageRouteInfo>? children})
      : super(
          MultiCaptureRoute.name,
          initialChildren: children,
        );

  static const String name = 'MultiCaptureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MultiCaptureScreen();
    },
  );
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingScreen();
    },
  );
}

/// generated route for
/// [PhotoBoothShell]
class PhotoBoothRoute extends PageRouteInfo<void> {
  const PhotoBoothRoute({List<PageRouteInfo>? children})
      : super(
          PhotoBoothRoute.name,
          initialChildren: children,
        );

  static const String name = 'PhotoBoothRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PhotoBoothShell();
    },
  );
}

/// generated route for
/// [PhotoDetailsScreen]
class PhotoDetailsRoute extends PageRouteInfo<PhotoDetailsRouteArgs> {
  PhotoDetailsRoute({
    Key? key,
    required String photoId,
    List<PageRouteInfo>? children,
  }) : super(
          PhotoDetailsRoute.name,
          args: PhotoDetailsRouteArgs(
            key: key,
            photoId: photoId,
          ),
          initialChildren: children,
        );

  static const String name = 'PhotoDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PhotoDetailsRouteArgs>();
      return PhotoDetailsScreen(
        key: args.key,
        photoId: args.photoId,
      );
    },
  );
}

class PhotoDetailsRouteArgs {
  const PhotoDetailsRouteArgs({
    this.key,
    required this.photoId,
  });

  final Key? key;

  final String photoId;

  @override
  String toString() {
    return 'PhotoDetailsRouteArgs{key: $key, photoId: $photoId}';
  }
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<SettingsRouteArgs> {
  SettingsRoute({
    Key? key,
    SettingsPageKey initialPage = SettingsPageKey.project,
    List<PageRouteInfo>? children,
  }) : super(
          SettingsRoute.name,
          args: SettingsRouteArgs(
            key: key,
            initialPage: initialPage,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsRouteArgs>(
          orElse: () => const SettingsRouteArgs());
      return SettingsScreen(
        key: args.key,
        initialPage: args.initialPage,
      );
    },
  );
}

class SettingsRouteArgs {
  const SettingsRouteArgs({
    this.key,
    this.initialPage = SettingsPageKey.project,
  });

  final Key? key;

  final SettingsPageKey initialPage;

  @override
  String toString() {
    return 'SettingsRouteArgs{key: $key, initialPage: $initialPage}';
  }
}

/// generated route for
/// [ShareScreen]
class ShareRoute extends PageRouteInfo<void> {
  const ShareRoute({List<PageRouteInfo>? children})
      : super(
          ShareRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShareRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ShareScreen();
    },
  );
}

/// generated route for
/// [SingleCaptureScreen]
class SingleCaptureRoute extends PageRouteInfo<void> {
  const SingleCaptureRoute({List<PageRouteInfo>? children})
      : super(
          SingleCaptureRoute.name,
          initialChildren: children,
        );

  static const String name = 'SingleCaptureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SingleCaptureScreen();
    },
  );
}

/// generated route for
/// [StartScreen]
class StartRoute extends PageRouteInfo<void> {
  const StartRoute({List<PageRouteInfo>? children})
      : super(
          StartRoute.name,
          initialChildren: children,
        );

  static const String name = 'StartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StartScreen();
    },
  );
}
