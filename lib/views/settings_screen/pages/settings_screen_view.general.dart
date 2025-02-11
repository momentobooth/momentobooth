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
        icon: LucideIcons.image,
        title: "Treat single photo as collage",
        subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
        value: () => viewModel.singlePhotoIsCollageSetting,
        onChanged: controller.onSinglePhotoIsCollageChanged,
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
