part of '../settings_overlay_view.dart';

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
            const Text('Flutter version: ${FlutterVersion.version}'),
            const SizedBox(height: 8),
            Text('Helper library version: ${helperLibraryVersionInfo.libraryVersion}'),
            Text('Helper library Rust version: ${helperLibraryVersionInfo.rustVersion}'),
            Text('Helper library target: ${helperLibraryVersionInfo.rustTarget}'),
            const SizedBox(height: 8),
            Text('libusb version: ${helperLibraryVersionInfo.libusbVersion}'),
            Text('libgphoto2 version: ${helperLibraryVersionInfo.libgphoto2Version}${libgphoto2GitRev.isNotEmpty ? ' (git rev ${libgphoto2GitRev.substring(0, 7)})' : ''}'),
            const SizedBox(height: 16),
            Observer(builder: (context) => _versionHistory(context, getIt<UpdateManager>().versionHistory)),
          ],
        ),
      ],
    ),
  );
}

/// Lists which version was taken into use on which date, newest first.
Widget _versionHistory(BuildContext context, VersionHistory versionHistory) {
  List<VersionHistoryEntry> entries = versionHistory.entriesByFirstUse.reversed.toList();
  if (entries.isEmpty) return const SizedBox();

  return Expander(
    header: const Text('Version history'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        for (final entry in entries)
          Text('${entry.fullVersion} — in use since ${_formatDate(entry.firstUsed)}, last started ${_formatDate(entry.lastUsed)}'),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
