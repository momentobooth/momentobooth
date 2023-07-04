part of 'settings_screen_view.dart';


Widget _getTemplatingSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  const buttonPadding = SizedBox(width: 10,);
  return FluentSettingsPage(
    title: "Templating",
    blocks: [
      _templateSettings(viewModel, controller),
      FluentSettingsBlock(
        title: "Template preview",
        settings: [
          Row(
            children: [
              Button(
                child: const Text('No photo'),
                onPressed: () => viewModel.previewTemplate = 0,
              ),
              buttonPadding,
              Button(
                child: const Text('1 photo'),
                onPressed: () => viewModel.previewTemplate = 1,
              ),
              buttonPadding,
              Button(
                child: const Text('2 photos'),
                onPressed: () => viewModel.previewTemplate = 2,
              ),
              buttonPadding,
              Button(
                child: const Text('3 photos'),
                onPressed: () => viewModel.previewTemplate = 3,
              ),
              buttonPadding,
              Button(
                child: const Text('4 photos'),
                onPressed: () => viewModel.previewTemplate = 4,
              ),
            ],
          ),
          const SizedBox(height: 10,),
          const Text("Explanation: Red border = padding for printing, will be cut-off if set correctly, White border = gap size"),
          const SizedBox(height: 10,),
          _getTemplateExampleRow(viewModel, controller),
        ]
      ),
    ],
  );
}

Widget _getTemplateExampleRow(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  const double height = 600;
  return Row(
    children: [
      const SizedBox(height: height,),
      Observer(
        builder: (context) => RotatedBox(
          quarterTurns: -1 * viewModel.previewTemplateRotation,
          child: SizedBox(
            height: height,
            child: FittedBox(
              child: PhotoCollage(
                key: viewModel.collageKey,
                debug: viewModel.previewTemplate,
                aspectRatio: 1/viewModel.collageAspectRatioSetting,
                padding: viewModel.collagePaddingSetting,
                // decodeCallback: viewModel.collageReady,
              ),
            ),
          ),
        )
      ),
    ],
  );
}

Widget _templateSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsBlock(
    title: "Creative",
    settings: [
      _getInput(
        icon: FluentIcons.aspect_ratio,
        title: "Collage aspect ratio",
        subtitle: "Controls the aspect ratio of the generated collages. Think about this together with paper print size.",
        smallChange: 0.1,
        value: () => viewModel.collageAspectRatioSetting,
        onChanged: controller.onCollageAspectRatioChanged,
      ),
      _getInput(
        icon: FluentIcons.field_filled,
        title: "Collage padding",
        subtitle: "Controls the padding around the aspect ratio of the generated collages. Think about this together with paper print size.",
        value: () => viewModel.collagePaddingSetting,
        onChanged: controller.onCollagePaddingChanged,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Observer(
          builder: (context) => Text("→ Padding will be ${(viewModel.pageHeightSetting/1000 * viewModel.collagePaddingSetting).toStringAsPrecision(3)} mm with ${viewModel.pageHeightSetting} mm page height.")
        ),
      ),
      _getFolderPickerCard(
        icon: FluentIcons.fabric_report_library,
        title: "Collage background templates location",
        subtitle: "Location to look for template files",
        dialogTitle: "Select templates location",
        controller: controller.templatesFolderSettingController,
        onChanged: controller.onTemplatesFolderChanged,
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
        child: Observer(
          builder: (context) => Text("→ Output resolution based on aspect ratio (${viewModel.collageAspectRatioSetting}) and padding (${viewModel.collagePaddingSetting}) and multiplier will be ${(viewModel.outputResHeightExcl).round()}×${(viewModel.outputResWidthExcl).round()} without and ${(viewModel.outputResHeightIncl).round()}×${(viewModel.outputResWidthIncl).round()} with padding"),
        )
      ),
    ],
  );
}
