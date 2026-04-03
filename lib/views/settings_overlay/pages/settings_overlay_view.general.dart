part of '../settings_overlay_view.dart';

Widget _getGeneralSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsListPage(
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
      SettingsSection(
        title: "Control",
        settings: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("When control is enabled, MomentoBooth can receive commands and send updates to external applications, such as Home Assistant. "
            "This allows you to integrate MomentoBooth into your smart home setup and automate it based on various triggers. Currently this is done through MQTT, configure this in the MQTT settings."),
          ),
          SettingsToggleTile(
            icon: LucideIcons.sendToBack,
            title: "Enable control features",
            subtitle: "When enabled, MomentoBooth will publish updates about its state and listen for incoming commands to control it. If you don't use this, it's best to keep it disabled for security and performance reasons.",
            value: () => viewModel.allowControlSetting,
            onChanged: controller.onAllowControlChanged,
          ),
          SettingsNumberEditTile(
            icon: LucideIcons.shieldEllipsis,
            title: "Control disable duration after touch",
            subtitle: 'In milliseconds. After a user interacts with the photobooth (e.g. by touching the screen), control features will be automatically disabled for this duration to prevent unwanted remote interactions while people are using the booth.',
            value: () => viewModel.controlDisableDurationMsAfterTouchSetting,
            onFinishedEditing: controller.onControlDisableDurationAfterTouchChanged,
          ),
          SettingsNumberEditTile(
            icon: LucideIcons.history,
            title: "Control history retention duration",
            subtitle: 'In seconds. MomentoBooth keeps a history of received control commands for this duration. This can be used to provide context to new commands.',
            value: () => viewModel.controlHistoryDurationSecondsSetting,
            onFinishedEditing: controller.onControlHistoryDurationSecondsChanged,
          ),
        ]
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
