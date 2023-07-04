part of 'settings_screen_view.dart';


Widget _getTemplatingSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Templating",
    blocks: [
      _templateSettings(viewModel, controller),
      FluentSettingsBlock(
        title: "Template preview",
        settings: [
          _getTemplateExampleRow(viewModel, controller),
        ]
      ),
    ],
  );
}

Widget _getTemplateExampleRow(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return Row(
    children: [
      RotatedBox(
        quarterTurns: -1 * viewModel.previewTemplateRotation,
        child: SizedBox(
          height: 450,
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
      _getBooleanInput(
        icon: FluentIcons.picture_center,
        title: "Treat single photo as collage",
        subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
        value: () => viewModel.singlePhotoIsCollageSetting,
        onChanged: controller.onSinglePhotoIsCollageChanged,
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
