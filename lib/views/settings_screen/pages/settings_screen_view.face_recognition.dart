part of '../settings_screen_view.dart';

Widget _getFaceRecognitionSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Face recognition",
    blocks: [
      SettingsToggleTile(
        icon: LucideIcons.scanFace,
        title: "Enable face recognition",
        subtitle: "If enabled, the application allows face recognition features to be used.",
        value: () => viewModel.faceRecognitionEnabled,
        onChanged: controller.onFaceRecognitionEnableChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.server,
        title: "Server address",
        subtitle: "The address of the server to connect to for face recognition.",
        controller: controller.faceRecognitionServerUrlController,
        onFinishedEditing: controller.onFaceRecognitionServerUrlChanged,
      ),
    ],
  );
}
