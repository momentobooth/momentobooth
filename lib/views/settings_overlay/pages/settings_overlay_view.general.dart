part of '../settings_overlay_view.dart';

Widget _getGeneralSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "General",
    blocks: [
      SettingsNumberEditTile(
        icon: LucideIcons.timer,
        title: "Capture delay",
        subtitle: 'In seconds',
        value: () => viewModel.captureDelaySecondsSetting,
        onFinishedEditing: controller.onCaptureDelaySecondsChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.folderDot,
        title: "Load last project on start",
        subtitle: "When enabled, MomentoBooth will load the last opened project when it starts.",
        value: () => viewModel.loadLastProjectSetting,
        onChanged: controller.onLoadLastProjectChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.power,
        title: "Try to keep the computer the screen awake",
        subtitle: "When enabled, MomentoBooth will issue a 'wakelock' which should keep your computer and display awake.",
        value: () => viewModel.enableWakelockSetting,
        onChanged: controller.onEnableWakelockChanged,
      ),
      const SettingsSection(
        title: "Hotkeys",
        settings: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+S to toggle this settings screen."),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Hit Ctrl+O browse for and open a project folder."),
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
