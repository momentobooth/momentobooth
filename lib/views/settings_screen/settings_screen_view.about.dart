part of 'settings_screen_view.dart';

Widget get _aboutTab {
  String libgphoto2GitRev = const String.fromEnvironment("LIBGPHOTO2_GIT_REV");

  return Center(
    child: ListView(
      shrinkWrap: true,
      children: [
        SvgPicture.asset('assets/svg/logo.svg'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Thank you for using ${packageInfo.appName}!"),
            const SizedBox(height: 16),
            Text('App version: ${packageInfo.version} (build ${packageInfo.buildNumber})'),
            const Text('Flutter version: $flutterVersion'),
            const SizedBox(height: 8),
            Text('Helper library version: ${helperLibraryVersionInfo.libraryVersion}'),
            Text('Helper library Rust version: ${helperLibraryVersionInfo.rustVersion}'),
            Text('Helper library target: ${helperLibraryVersionInfo.rustTarget}'),
            const SizedBox(height: 8),
            Text('libgphoto2 version: ${helperLibraryVersionInfo.libgphoto2Version}${libgphoto2GitRev.isNotEmpty ? ' (git rev ${libgphoto2GitRev.substring(0, 7)})' : ''}'),
            Text('libgexiv2 version: ${helperLibraryVersionInfo.libgexiv2Version}'),
            Text('libexiv2 version: ${helperLibraryVersionInfo.libexiv2Version}'),
          ],
        ),
      ],
    ),
  );
}
