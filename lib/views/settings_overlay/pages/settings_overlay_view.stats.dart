part of '../settings_overlay_view.dart';

final _projectStatColor = Colors.purple;

Widget _getStatsTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsListPage(
    title: "Statistics",
    blocks: [
      Observer(
        builder: (context) => SettingsTextDisplayTile(
          icon: LucideIcons.cctv,
          title: "Live view frames – this session",
          subtitle: "The number of live view frames processed from the start of the camera\nValue shows: Valid frames / Undecodable frames / Duplicate frames",
          text: "${getIt<StatsManager>().validLiveViewFrames} / ${getIt<StatsManager>().invalidLiveViewFrames} / ${getIt<StatsManager>().duplicateLiveViewFrames}",
        ),
      ),
      SizedBox(height: 16),
      Observer(builder: (context) => _statsLegend(context, showProject: getIt<ProjectManager>().isOpen)),
      _statTile(
        icon: LucideIcons.mousePointerClick,
        title: "Taps",
        subtitle: "The number of taps in the app (outside settings)",
        value: (s) => s.taps,
      ),
      _statTile(
        icon: LucideIcons.printer,
        title: "Printed pictures – Normal size",
        subtitle: "The number of prints (e.g. 2 prints of the same pictures will count as 2 as well)",
        value: (s) => s.printedPhotos,
      ),
      _statTile(
        icon: LucideIcons.printer,
        title: "Printed pictures – Small",
        subtitle: "The number of small prints (e.g. 2 prints of the same pictures will count as 2 as well)",
        value: (s) => s.printedPhotosSmall,
      ),
      _statTile(
        icon: LucideIcons.printer,
        title: "Printed pictures – Tiny",
        subtitle: "The number of tiny prints (e.g. 2 prints of the same pictures will count as 2 as well)",
        value: (s) => s.printedPhotosTiny,
      ),
      _statTile(
        icon: LucideIcons.upload,
        title: "Uploaded pictures",
        subtitle: "The number of uploaded pictures",
        value: (s) => s.uploadedPhotos,
      ),
      _statTile(
        icon: LucideIcons.aperture,
        title: "Captured photos",
        subtitle: "The number of photo captures (e.g. a multi capture picture would increase this by 4)",
        value: (s) => s.capturedPhotos,
      ),
      _statTile(
        icon: LucideIcons.image,
        title: "Created single shot pictures",
        subtitle: "The number of single capture pictures created, including retakes",
        value: (s) => s.createdSinglePhotos,
      ),
      _statTile(
        icon: LucideIcons.undo,
        title: "Retakes",
        subtitle: "The number of retakes for (single) photo captures",
        value: (s) => s.retakes,
      ),
      _statTile(
        icon: LucideIcons.images,
        title: "Created multi shot pictures",
        subtitle: "The number of multi shot pictures created, including changes",
        value: (s) => s.createdMultiCapturePhotos,
      ),
      _statTile(
        icon: LucideIcons.undo,
        title: "Collage changes",
        subtitle: "The number of times a user went back to change a collage",
        value: (s) => s.collageChanges,
      ),
    ],
  );
}

/// Explains what the (optionally shown) two chip colors on each row below mean, so the rows themselves don't need to repeat the labels.
Widget _statsLegend(BuildContext context, {required bool showProject}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: 16,
      children: [
        _statsLegendEntry(context, color: FluentTheme.of(context).accentColor, label: "Global"),
        if (showProject) _statsLegendEntry(context, color: _projectStatColor, label: "Project"),
      ],
    ),
  );
}

Widget _statsLegendEntry(BuildContext context, {required Color color, required String label}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Text(label, style: FluentTheme.of(context).typography.caption),
    ],
  );
}

/// Builds a [SettingsTile] showing [value] taken from both the global statistics and,
/// when a project is open, that project's statistics, next to each other.
/// See [_statsLegend] for what the colors mean.
Widget _statTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required int Function(Stats s) value,
}) {
  return Observer(
    builder: (context) {
      final projectManager = getIt<ProjectManager>();
      final isProjectOpen = projectManager.isOpen;
      return SettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        setting: Row(
          spacing: 8,
          children: [
            SettingsValueChip(text: value(getIt<StatsManager>().stats).toString()),
            if (isProjectOpen) SettingsValueChip(text: value(projectManager.stats).toString(), color: _projectStatColor),
          ],
        ),
      );
    },
  );
}
