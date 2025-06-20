part of '../settings_overlay_view.dart';

Widget _getExperimentalTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "Experimental settings",
    blocks: [
      _getExperimentalBlock(viewModel, controller),
    ],
  );
}

Widget _getExperimentalBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsSection(
    title: "Video mode",
    settings: [
      SettingsToggleTile(
        icon: LucideIcons.video,
        title: "Enable video mode",
        subtitle: "Enables video capture mode, which can be used to record short videos.",
        value: () => viewModel.enableVideoModeSetting,
        onChanged: controller.onEnableVideoModeChanged,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.timer,
        title: "Video record length",
        subtitle: "How long video recordings should last.",
        value: () => viewModel.videoDurationSetting,
        onFinishedEditing: controller.onVideoDurationChanged,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.timer,
        title: "Video pre record delay",
        subtitle: "How long video before the video is supposed to start to instruct the camera to start the recording in ms.",
        value: () => viewModel.videoPreRecordDelayMsSetting,
        onFinishedEditing: controller.onVideoPreRecordDelayMsChanged,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.timer,
        title: "Video post record delay",
        subtitle: "How long video after the video is supposed to end to instruct the camera to stop the recording in ms.",
        value: () => viewModel.videoPostRecordDelayMsSetting,
        onFinishedEditing: controller.onVideoPostRecordDelayMsChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.squareCode,
        title: "FFMPEG arguments",
        subtitle: "The arguments, separated by ; to be fed into FFMPEG when recording audio.",
        controller: controller.ffmpegArgumentsForRecordingController,
        onFinishedEditing: controller.onFfmpegArgumentsForRecordingChanged,
      ),
      SettingsSecretEditTile(
        icon: LucideIcons.squareAsterisk,
        title: "OpenAI API key",
        subtitle: "API key for audio processing.",
        secretStorageKey: openaiAPISecretKey,
        onSecretStored: getIt<MqttManager>().notifyPasswordChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.messageSquareMore,
        title: "LLM transcript summary prompt",
        subtitle: "The prompt that will be fed to the LLM in order to summarize the transcript of the video.",
        controller: controller.textSummaryPromptController,
        onFinishedEditing: controller.onTextSummaryPromptChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.codesandbox,
        title: "LLM model to use",
        subtitle: "The model that will be requested for text processing.",
        controller: controller.llmModelController,
        onFinishedEditing: controller.onLlmModelChanged,
      ),
    ],
  );
}
