part of 'settings_screen_view.dart';

Widget _getDebugTab(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Debug and Stats",
    blocks: [
      FluentSettingsBlock(
        title: "Stats",
        settings: [
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.touch,
              title: "Taps",
              subtitle: "The number of taps in the app (outside settings)",
              text: StatsManager.instance.stats.taps.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.front_camera,
              title: "Live view frames",
              subtitle: "The number of live view frames processed from the start of the camera\nValue shows: Valid frames / Undecodable frames",
              text: "${StatsManager.instance.validLiveViewFrames} / ${StatsManager.instance.invalidLiveViewFrames}",
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.print,
              title: "Printed pictures",
              subtitle: "The number of prints (e.g. 2 prints of the same pictures will count as 2 as well)",
              text: StatsManager.instance.stats.printedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.upload,
              title: "Uploaded pictures",
              subtitle: "The number of uploaded pictures",
              text: StatsManager.instance.stats.uploadedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.camera,
              title: "Captured photos",
              subtitle: "The number of photo captures (e.g. a multi capture picture would increase this by 4)",
              text: StatsManager.instance.stats.capturedPhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.photo2,
              title: "Created single shot pictures",
              subtitle: "The number of single capture pictures created",
              text: StatsManager.instance.stats.createdSinglePhotos.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.undo,
              title: "Retakes",
              subtitle: "The number of retakes for (single) photo captures",
              text: StatsManager.instance.stats.retakes.toString(),
            ),
          ),
          Observer(
            builder: (context) => TextDisplayCard(
              icon: FluentIcons.photo_collection,
              title: "Created multi shot pictures",
              subtitle: "The number of multi shot pictures created",
              text: StatsManager.instance.stats.createdMultiCapturePhotos.toString(),
            ),
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Debug settings",
        settings: [
          BooleanInputCard(
            icon: FluentIcons.count,
            title: "Show FPS count",
            subtitle: "Show the FPS count in the upper right corner.",
            value: () => viewModel.debugShowFpsCounter,
            onChanged: controller.onDebugShowFpsCounterChanged,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Debug actions",
        settings: [
          ButtonCard(
            icon: FluentIcons.error,
            title: "Report fake error",
            subtitle: "Test whether error reporting (to Sentry) works",
            buttonText: "Report Fake Error",
            onPressed: () => throw Exception("This is a fake error to test error reporting"),
          ),
        ],
      ),
    ],
  );
}
