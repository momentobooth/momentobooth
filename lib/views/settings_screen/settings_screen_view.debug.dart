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
              text: StatsManagerBase.instance.stats[StatFields.taps].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.front_camera,
              title: "Live view frames",
              subtitle: "The number of live view frames that have been shown",
              text: StatsManagerBase.instance.stats[StatFields.liveViewFrames].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.print,
              title: "Printed pictures",
              subtitle: "The number of prints (e.g. 2 prints of the same pictures will count as 2 as well)",
              text: StatsManagerBase.instance.stats[StatFields.printedPhotos].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.upload,
              title: "Uploaded pictures",
              subtitle: "The number of uploaded pictures",
              text: StatsManagerBase.instance.stats[StatFields.uploadedPhotos].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.camera,
              title: "Captured photos",
              subtitle: "The number of photo captures (e.g. a multi capture picture would increase this by 4)",
              text: StatsManagerBase.instance.stats[StatFields.capturedPhotos].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.photo2,
              title: "Created single shot pictures",
              subtitle: "The number of single capture pictures created",
              text: StatsManagerBase.instance.stats[StatFields.createdSinglePhotos].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.undo,
              title: "Retakes",
              subtitle: "The number of retakes for (single) photo captures",
              text: StatsManagerBase.instance.stats[StatFields.retakes].toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              context: context,
              icon: FluentIcons.photo_collection,
              title: "Created multi shot pictures",
              subtitle: "The number of multi shot pictures created",
              text: StatsManagerBase.instance.stats[StatFields.createdMultiCapturePhotos].toString(),
            ),
          ),
        ],
      ),
    ],
  );
}
