part of '../settings_screen_view.dart';

// TODO figure out how to define when override happens and when a setting is just not set.
Widget _getProjectSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Project",
    blocks: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Text("These settings are project-specific and override global behaviour. The settings are saved in your project directory, so the settings are also used when the project is opened on another computer.", style: TextStyle(fontSize: 16)),
      ),
      FluentSettingsBlock(
        title: "Project settings",
        settings: [
          ColorInputCard(
            icon: LucideIcons.paintbrushVertical,
            title: "Primary color",
            subtitle: "The primary color of the app",
            value: () => viewModel.primaryColorSetting,
            onChanged: controller.onPrimaryColorChanged,
          ),
          BooleanInputCard(
            icon: LucideIcons.palette,
            title: "Colorize confetti to the theme color",
            subtitle: "If enabled, confetti will will be various shades of the theme color. Else, random colors will be used.",
            value: () => viewModel.customColorConfettiSetting,
            onChanged: controller.onCustomColorConfettiChanged,
          ),
          TextInputCard(
            icon: LucideIcons.heading,
            title: "Alternative 'Touch to start' title text",
            subtitle: "The override text that will be shown on the Start screen instead of 'Touch to start'. Leave empty to show the default text from the translations data.",
            controller: controller.introScreenTouchToStartOverrideTextController,
            onFinishedEditing: controller.onIntroScreenTouchToStartOverrideText,
          ),
          NumberInputCard(
            icon: LucideIcons.ratio,
            title: "Aspect ratio",
            subtitle: 'The aspect ratio to which live view and captures are cropped.',
            value: () => viewModel.liveViewAndCaptureAspectRatioSetting,
            onFinishedEditing: controller.onLiveViewAndCaptureAspectRatioChanged,
            smallChange: 0.1,
          ),
          BooleanInputCard(
            icon: LucideIcons.image,
            title: "Treat single photo as collage",
            subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
            value: () => viewModel.singlePhotoIsCollageSetting,
            onChanged: controller.onSinglePhotoIsCollageChanged,
          ),
        ]
      ),
    ],
  );
}
