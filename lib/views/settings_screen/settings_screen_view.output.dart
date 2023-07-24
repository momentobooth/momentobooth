part of 'settings_screen_view.dart';

Widget _getOutputSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Output",
    blocks: [
      FluentSettingsBlock(
        title: "Local",
        settings: [
          _getFolderPickerCard(
            icon: FluentIcons.fabric_picture_library,
            title: "Local photo storage location",
            subtitle: "Location where the output images will be stored",
            controller: controller.localFolderSettingController,
            onChanged: controller.onLocalFolderChanged,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Share using internet",
        settings: [
          _getTextInput(
            icon: FluentIcons.my_network,
            title: "Firefox Send URL",
            subtitle: "Firefox Send Server URL",
            controller: controller.firefoxSendServerUrlController,
            onChanged: controller.onFirefoxSendServerUrlChanged,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Image settings",
        settings: [
          _getComboBoxCard(
            icon: FluentIcons.file_image,
            title: "Image file type",
            subtitle: "What kind of file to generate",
            items: viewModel.exportFormats,
            value: () => viewModel.exportFormat,
            onChanged: controller.onExportFormatChanged,
          ),
          _getInput(
            icon: FluentIcons.equalizer,
            title: "JPG quality",
            subtitle: 'Export quality (higher is bigger files)',
            value: () => viewModel.jpgQuality,
            onChanged: controller.onJpgQualityChanged,
          ),
          _getInput(
            icon: FluentIcons.picture_stretch,
            title: "Output resolution multiplier",
            subtitle: 'Controls image resolution',
            value: () => viewModel.resolutionMultiplier,
            onChanged: controller.onResolutionMultiplierChanged,
            smallChange: 0.1,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("→ Output resolution based on aspect ratio (${viewModel.collageAspectRatioSetting}) and padding (${viewModel.collagePaddingSetting}) and multiplier will be ${(viewModel.outputResHeightExcl).round()}×${(viewModel.outputResWidthExcl).round()} without and ${(viewModel.outputResHeightIncl).round()}×${(viewModel.outputResWidthIncl).round()} with padding"),
          ),
        ],
      ),
    ],
  );
}
