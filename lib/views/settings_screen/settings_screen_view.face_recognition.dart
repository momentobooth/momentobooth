part of 'settings_screen_view.dart';

Widget _getFaceRecognitionSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Face recognition",
    blocks: [
      BooleanInputCard(
        icon: FluentIcons.toggle_border,
        title: "Enable face recognition",
        subtitle: "If enabled, the application allows face recognition features to be used.",
        value: () => viewModel.faceRecognitionEnabled,
        onChanged: controller.onFaceRecognitionEnableChanged,
      ),
      TextInputCard(
        icon: FluentIcons.server,
        title: "Server address",
        subtitle: "The address of the server to connect to for face recognition.",
        controller: controller.faceRecognitionServerUrlController,
        onFinishedEditing: controller.onFaceRecognitionServerUrlChanged,
      ),
    ],
  );
}
