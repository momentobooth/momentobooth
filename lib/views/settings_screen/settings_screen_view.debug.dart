part of 'settings_screen_view.dart';

Widget _getDebugTab(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Debug",
    blocks: [
      FluentSettingsBlock(
        title: "Actions",
        settings: [
          ButtonCard(
            icon: FluentIcons.speakers,
            title: "Play audio sample",
            subtitle: "Play a sample mp3 file, to verify whether audio file playback is working. Please note that the User interface > Sound Effects > Enable Sound Effects setting needs to be enabled.",
            buttonText: "Audio test",
            onPressed: controller.onPlayAudioSamplePressed,
          ),
          ButtonCard(
            icon: FluentIcons.error,
            title: "Report fake error",
            subtitle: "Test whether error reporting (to Sentry) works",
            buttonText: "Report Fake Error",
            onPressed: () => throw Exception("This is a fake error to test error reporting"),
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
    ],
  );
}
