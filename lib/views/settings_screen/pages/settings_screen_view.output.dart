part of '../settings_screen_view.dart';

Widget _getOutputSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Output",
    blocks: [
      SettingsSection(
        title: "Local",
        settings: [
          Text("Collages are saved to the Output folder of your project.")
        ],
      ),
      SettingsSection(
        title: "Share using internet",
        settings: [
          SettingsTextEditTile(
            icon: LucideIcons.globe,
            title: "Firefox Send URL",
            subtitle: "Firefox Send Server URL",
            controller: controller.firefoxSendServerUrlController,
            onFinishedEditing: controller.onFirefoxSendServerUrlChanged,
          ),
        ],
      ),
      SettingsSection(
        title: "Image settings",
        settings: [
          SettingsComboBoxTile(
            icon: LucideIcons.fileImage,
            title: "Image file type",
            subtitle: "What kind of file to generate",
            items: viewModel.exportFormats,
            value: () => viewModel.exportFormat,
            onChanged: controller.onExportFormatChanged,
          ),
          SettingsNumberEditTile(
            icon: LucideIcons.fileSliders,
            title: "JPG quality",
            subtitle: 'Export quality (higher is bigger files)',
            value: () => viewModel.jpgQuality,
            onFinishedEditing: controller.onJpgQualityChanged,
          ),
          SettingsNumberEditTile(
            icon: LucideIcons.proportions,
            title: "Output resolution multiplier",
            subtitle: 'Controls image resolution',
            value: () => viewModel.resolutionMultiplier,
            onFinishedEditing: controller.onResolutionMultiplierChanged,
            smallChange: 0.1,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("→ Output resolution based on aspect ratio (${viewModel.collageAspectRatioSetting}) and padding (${viewModel.collagePaddingSetting}) and multiplier will be ${viewModel.outputResHeightExcl.round()}×${viewModel.outputResWidthExcl.round()} without and ${viewModel.outputResHeightIncl.round()}×${viewModel.outputResWidthIncl.round()} with padding"),
          ),
        ],
      ),
    ],
  );
}
