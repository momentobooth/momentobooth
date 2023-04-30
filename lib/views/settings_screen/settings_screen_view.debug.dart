part of 'settings_screen_view.dart';

Widget _getDebugTab(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Debug and Stats",
    blocks: [
      FluentSettingsBlock(
        title: "Stats",
        settings: [
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.touch,
              title: "Taps",
              subtitle: "The number of taps in the app (outside settings)",
              text: StatsManagerBase.instance.stats.taps.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.front_camera,
              title: "Live view frames (total/dropped by app)",
              subtitle: "The number of live view frames that have been shown",
              text: "${StatsManagerBase.instance.stats.liveViewFrames} / ${StatsManagerBase.instance.stats.liveViewFramesDroppedByApp}",
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.print,
              title: "Printed pictures",
              subtitle: "The number of prints (e.g. 2 prints of the same pictures will count as 2 as well)",
              text: StatsManagerBase.instance.stats.printedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.upload,
              title: "Uploaded pictures",
              subtitle: "The number of uploaded pictures",
              text: StatsManagerBase.instance.stats.uploadedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.camera,
              title: "Captured photos",
              subtitle: "The number of photo captures (e.g. a multi capture picture would increase this by 4)",
              text: StatsManagerBase.instance.stats.capturedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.photo2,
              title: "Created single shot pictures",
              subtitle: "The number of single capture pictures created",
              text: StatsManagerBase.instance.stats.createdSinglePhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.undo,
              title: "Retakes",
              subtitle: "The number of retakes for (single) photo captures",
              text: StatsManagerBase.instance.stats.retakes.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.photo_collection,
              title: "Created multi shot pictures",
              subtitle: "The number of multi shot pictures created",
              text: StatsManagerBase.instance.stats.createdMultiCapturePhotos.toString(),
            ),
          ),
        ],
      ),
    ],
  );
}
