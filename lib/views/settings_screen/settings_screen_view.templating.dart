part of 'settings_screen_view.dart';


Widget _getTemplatingSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Templating",
    blocks: [_getTemplateExampleRow(viewModel, controller)]
  );
}

Widget _getTemplateExampleRow(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return Row(
    children: [
      SizedBox(
        height: 450,
        child: FittedBox(
          child: PhotoCollage(
            key: viewModel.collageKey,
            debugMode: true,
            choiceOverride: ObservableList.of([1]),
            aspectRatio: 1/viewModel.collageAspectRatioSetting,
            padding: viewModel.collagePaddingSetting,
            // decodeCallback: viewModel.collageReady,
          ),
        ),
      ),
    ],
  );
}