part of '../settings_overlay_view.dart';

Widget _getProjectSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsListPage(
    title: "Project",
    blocks: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Text("These settings are project-specific and override global behaviour. The settings are saved in your project directory, so the settings are also used when the project is opened on another computer.", style: TextStyle(fontSize: 16)),
      ),
      Builder(
        builder: (context) {
          if (!getIt<ProjectManager>().isOpen) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: InfoBar(title: Text("Project settings can only be viewed and modified if a project is loaded."), severity: InfoBarSeverity.warning,),
            );
          }
          return SettingsSection(
            title: "Project settings",
            settings: [
              SettingsComboBoxTile(
                icon: LucideIcons.appWindow,
                title: "UI theme",
                subtitle: "The UI theme of the app.",
                items: viewModel.uiThemeOptions,
                value: () => viewModel.uiTheme,
                onChanged: controller.onUiThemeChanged,
              ),
              SettingsColorPickTile(
                icon: LucideIcons.paintbrushVertical,
                title: "Primary color",
                subtitle: "The primary color of the app",
                value: () => viewModel.primaryColorSetting,
                onChanged: controller.onPrimaryColorChanged,
              ),
              SettingsToggleTile(
                icon: LucideIcons.partyPopper,
                title: "Display confetti 🎉",
                subtitle: "If enabled, confetti will shower the share screen!",
                value: () => viewModel.displayConfettiSetting,
                onChanged: controller.onDisplayConfettiChanged,
              ),
              SettingsToggleTile(
                icon: LucideIcons.palette,
                // FIXME why do we call it theme color here and primary color above?
                title: "Colorize confetti to the theme color",
                subtitle: "If enabled, confetti will will be various shades of the theme color. Else, random colors will be used.",
                value: () => viewModel.customColorConfettiSetting,
                onChanged: controller.onCustomColorConfettiChanged,
              ),
              SettingsTextEditTile(
                icon: LucideIcons.heading,
                title: "Alternative ‘Touch to start’ title text",
                subtitle: "The override text that will be shown on the Start screen instead of ‘Touch to start’. Leave empty to show the default text from the translations data.",
                controller: controller.introScreenTouchToStartOverrideTextController,
                onFinishedEditing: controller.onIntroScreenTouchToStartOverrideText,
              ),
              SettingsToggleTile(
                icon: LucideIcons.toggleRight,
                title: "Enable single photo capture",
                subtitle: "If enabled, a single picture capture will be available as a capture mode.",
                value: () => viewModel.enableSingleCaptureSetting,
                onChanged: controller.onEnableSingleCaptureChanged,
              ),
              SettingsToggleTile(
                icon: LucideIcons.image,
                title: "Treat single photo as collage",
                subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
                value: () => viewModel.singlePhotoIsCollageSetting,
                onChanged: controller.onSinglePhotoIsCollageChanged,
              ),
              SettingsToggleTile(
                icon: LucideIcons.toggleRight,
                title: "Enable collage photo capture",
                subtitle: "If enabled, a collage picture capture will be available as a capture mode.",
                value: () => viewModel.enableCollageCaptureSetting,
                onChanged: controller.onEnableCollageCaptureChanged,
              ),
              SettingsComboBoxTile(
                icon: LucideIcons.layoutGrid,
                title: "Collage mode",
                subtitle: "How to execute collage captures. Either let the user choose which and how many captures to include in the collage, or always use a fixed number of captures and layout.",
                items: viewModel.collageModeOptions,
                value: () => viewModel.collageModeSetting,
                onChanged: controller.onCollageModeChanged,
              ),
            ]
          );
        }
      ),
    ],
  );
}
