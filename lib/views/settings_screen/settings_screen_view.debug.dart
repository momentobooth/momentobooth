part of 'settings_screen_view.dart';

Widget _getDebugTab(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Debug",
    blocks: [
      FluentSettingsBlock(
        title: "Actions",
        settings: [
          ButtonCard(
            icon: LucideIcons.play,
            title: "Play audio sample",
            subtitle: "Play a sample mp3 file, to verify whether audio file playback is working. Please note that the User interface > Sound Effects > Enable Sound Effects setting needs to be enabled.",
            buttonText: "Audio test",
            onPressed: controller.onPlayAudioSamplePressed,
          ),
          ButtonCard(
            icon: LucideIcons.mailWarning,
            title: "Throw fake Dart error",
            subtitle: "This test whether error reporting (to Sentry) works",
            buttonText: "Run",
            onPressed: () => throw Exception("This is a fake error to test error reporting"),
          ),
          const ButtonCard(
            icon: LucideIcons.mailWarning,
            title: "Trigger panic in Rust code",
            subtitle: "This test whether error reporting (to Sentry) works",
            buttonText: "Run",
            onPressed: debug.panic,
          ),
          const ButtonCard(
            icon: LucideIcons.mailWarning,
            title: "Trigger bail in Rust code",
            subtitle: "This test whether error reporting (to Sentry) works",
            buttonText: "Run",
            onPressed: debug.fail,
          ),
          const ButtonCard(
            icon: LucideIcons.mailWarning,
            title: "Trigger file reading failure in Rust code",
            subtitle: "This test whether error reporting (to Sentry) works",
            buttonText: "Run",
            onPressed: debug.fileReadFail,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Debug settings",
        settings: [
          BooleanInputCard(
            icon: LucideIcons.monitorCog,
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
