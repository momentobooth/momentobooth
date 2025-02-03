part of '../settings_screen_view.dart';

Widget _getOutputSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Output",
    blocks: [
      FluentSettingsBlock(
        title: "Local",
        settings: [
          // FolderPickerCard(
          //   icon: LucideIcons.folderInput,
          //   title: "Local photo storage location",
          //   subtitle: "Location where the output images will be stored",
          //   controller: controller.localFolderSettingController,
          //   onChanged: controller.onLocalFolderChanged,
          // ),
        ],
      ),
      FluentSettingsBlock(
        title: "Share using internet",
        settings: [
          TextInputCard(
            icon: LucideIcons.globe,
            title: "Firefox Send URL",
            subtitle: "Firefox Send Server URL",
            controller: controller.firefoxSendServerUrlController,
            onFinishedEditing: controller.onFirefoxSendServerUrlChanged,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Image settings",
        settings: [
          ComboBoxCard(
            icon: LucideIcons.fileImage,
            title: "Image file type",
            subtitle: "What kind of file to generate",
            items: viewModel.exportFormats,
            value: () => viewModel.exportFormat,
            onChanged: controller.onExportFormatChanged,
          ),
          NumberInputCard(
            icon: LucideIcons.fileSliders,
            title: "JPG quality",
            subtitle: 'Export quality (higher is bigger files)',
            value: () => viewModel.jpgQuality,
            onFinishedEditing: controller.onJpgQualityChanged,
          ),
          NumberInputCard(
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
