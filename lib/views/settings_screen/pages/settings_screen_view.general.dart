part of '../settings_screen_view.dart';

Widget _getGeneralSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "General",
    blocks: [
      NumberInputCard(
        icon: LucideIcons.timer,
        title: "Capture delay",
        subtitle: 'In seconds',
        value: () => viewModel.captureDelaySecondsSetting,
        onFinishedEditing: controller.onCaptureDelaySecondsChanged,
      ),
      BooleanInputCard(
        icon: LucideIcons.folderDot,
        title: "Load last project on start",
        subtitle: "When enabled, MomentoBooth will load the last opened project when it starts.",
        value: () => viewModel.loadLastProjectSetting,
        onChanged: controller.onLoadLastProjectChanged,
      ),
      const FluentSettingsBlock(
        title: "Hotkeys",
        settings: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+S to toggle this settings screen."),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+F or Alt+Enter to toggle fullscreen mode."),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+M to go to the manual collage creation mode."),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+H to return to the homescreen from any place."),
          ),
        ]
      ),
    ],
  );
}
