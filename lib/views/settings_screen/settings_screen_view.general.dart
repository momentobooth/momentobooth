part of 'settings_screen_view.dart';

Widget _getGeneralSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) { 
  return FluentSettingsPage(
    title: "General",
    blocks: [
      _getInput(
        icon: FluentIcons.timer,
        title: "Capture delay",
        subtitle: 'In seconds',
        value: () => viewModel.captureDelaySecondsSetting,
        onChanged: controller.onCaptureDelaySecondsChanged,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Hit Ctrl+F or Alt+Enter to toggle fullscreen mode."),
      ),
      FluentSettingsBlock(
        title: "Creative",
        settings: [
          _getBooleanInput(
            icon: FluentIcons.picture_center,
            title: "Treat single photo as collage",
            subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
            value: () => viewModel.singlePhotoIsCollageSetting,
            onChanged: controller.onSinglePhotoIsCollageChanged,
          ),
        ],
      ),
    ],
  );
}
