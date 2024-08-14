part of 'settings_screen_view.dart';

Widget get _aboutTab {
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
          ],
        ),
      ],
    ),
  );
}
