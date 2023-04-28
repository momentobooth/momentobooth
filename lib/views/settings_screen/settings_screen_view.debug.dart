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
              icon: FluentIcons.camera,
              title: "Live view frames",
              subtitle: "The amount of live view frames that have been shown",
              text: StatsManagerBase.instance.liveViewFrames.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              icon: FluentIcons.print,
              title: "Printed pictures",
              subtitle: "The amount of prints (e.g. 2 prints of the same pictures will count as 2 as well)",
              text: StatsManagerBase.instance.printedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              icon: FluentIcons.upload,
              title: "Uploaded pictures",
              subtitle: "The amount of uploaded pictures",
              text: StatsManagerBase.instance.uploadedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              icon: FluentIcons.camera,
              title: "Captured photos",
              subtitle: "The amount of photo captures (e.g. a multi capture picture would increase this by 4)",
              text: StatsManagerBase.instance.capturedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              icon: FluentIcons.camera,
              title: "Created single shot pictures",
              subtitle: "The amount of single capture pictures created",
              text: StatsManagerBase.instance.createdSinglePhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => _getTextDisplay(
              icon: FluentIcons.camera,
              title: "Created multi shot pictures",
              subtitle: "The amount of multi shot pictures created",
              text: StatsManagerBase.instance.createdMultiCapturePhotos.toString(),
            ),
          ),
        ],
      ),
    ],
  );
}
