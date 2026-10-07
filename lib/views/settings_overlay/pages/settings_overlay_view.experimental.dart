part of '../settings_overlay_view.dart';

Widget _getExperimentalTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, BuildContext context) {
  return SettingsListPage(
    title: "Experimental settings",
    blocks: [
      _getExperimentalBlock(viewModel, controller),
      _getOpenAiEndpointsBlock(viewModel, controller, context),
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
      // Observer so the items update when endpoints are added, renamed or removed
      Observer(
        builder: (_) => SettingsComboBoxTile<String?>(
          icon: LucideIcons.audioLines,
          title: "Transcription endpoint",
          subtitle: "The OpenAI-compatible endpoint used to transcribe the recorded audio.",
          items: _openAiEndpointItems(viewModel),
          value: () => viewModel.transcriptionEndpointIdSetting,
          onChanged: controller.onTranscriptionEndpointChanged,
        ),
      ),
      SettingsTextEditTile(
        icon: LucideIcons.database,
        title: "Transcription model",
        subtitle: "The model that will be requested for audio transcription.",
        controller: controller.transcriptionModelController,
        onFinishedEditing: controller.onTranscriptionModelChanged,
      ),
      Observer(
        builder: (_) => SettingsComboBoxTile<String?>(
          icon: LucideIcons.messageSquareMore,
          title: "Summary endpoint",
          subtitle: "The OpenAI-compatible endpoint used to summarize the transcript.",
          items: _openAiEndpointItems(viewModel),
          value: () => viewModel.summaryEndpointIdSetting,
          onChanged: controller.onSummaryEndpointChanged,
        ),
      ),
      SettingsTextEditTile(
        icon: LucideIcons.messageSquareMore,
        title: "LLM transcript summary prompt",
        subtitle: "The prompt that will be fed to the LLM in order to summarize the transcript of the video.",
        controller: controller.textSummaryPromptController,
        onFinishedEditing: controller.onTextSummaryPromptChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.database,
        title: "LLM model to use",
        subtitle: "The model that will be requested for text processing.",
        controller: controller.llmModelController,
        onFinishedEditing: controller.onLlmModelChanged,
      ),
    ],
  );
}

List<ComboBoxItem<String?>> _openAiEndpointItems(SettingsOverlayViewModel viewModel) {
  return [
    for (final endpoint in viewModel.openAiEndpointsSetting)
      ComboBoxItem(value: endpoint.id, child: Text(endpoint.name)),
  ];
}

Widget _getOpenAiEndpointsBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, BuildContext context) {
  return SettingsSection(
    title: "OpenAI-compatible endpoints",
    settings: [
      Observer(builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final endpoint in viewModel.openAiEndpointsSetting)
              OpenAiEndpointTile(
                key: ValueKey(endpoint.id),
                endpoint: endpoint,
                onEdit: controller.onOpenAiEndpointSaved,
                onDelete: () => controller.onOpenAiEndpointDeleted(endpoint),
              ),
            const SizedBox(height: 16),
            FilledButton(
              child: const Text("+ Add endpoint"),
              onPressed: () {
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) => OpenAiEndpointEditDialog(
                    onSave: (endpoint, newApiKey, clearApiKey) {
                      Navigator.of(context).pop();
                      controller.onOpenAiEndpointSaved(endpoint, newApiKey, clearApiKey);
                    },
                  ),
                );
              },
            ),
          ],
        );
      }),
    ],
  );
}
