part of 'settings_screen_view.dart';

Widget _getGeneralSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) { 
  return FluentSettingsPage(
    title: "General",
    blocks: [
      FluentSettingsBlock(
        title: "Settings",
        settings: [
          _getInput(
            icon: FluentIcons.timer,
            title: "Capture delay",
            subtitle: 'In seconds',
            value: () => viewModel.captureDelaySecondsSetting,
            onChanged: controller.onCaptureDelaySecondsChanged,
          ),
          _getBooleanInput(
            icon: FluentIcons.favorite_star,
            title: "Display confetti 🎉",
            subtitle: "If enabled, confetti will shower the share screen!",
            value: () => viewModel.displayConfettiSetting,
            onChanged: controller.onDisplayConfettiChanged,
          ),
          _getInput(
            icon: FluentIcons.aspect_ratio,
            title: "Collage aspect ratio",
            subtitle: "Controls the aspect ratio of the generated collages. Think about this together with paper print size.",
            value: () => viewModel.collageAspectRatioSetting,
            onChanged: controller.onCollageAspectRatioChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Hit Ctrl+F or Alt+Enter to toggle fullscreen mode."),
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Creative",
        settings: [
          _getFolderPickerCard(
            icon: FluentIcons.fabric_report_library,
            title: "Collage background templates location",
            subtitle: "Location to look for template files",
            dialogTitle: "Select templates location",
            controller: controller.templatesFolderSettingController,
            onChanged: controller.onTemplatesFolderChanged,
          ),
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
