part of '../settings_overlay_view.dart';

Widget _getPrintRoutingSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage.fixed(
    title: "Print routing",
    body: PrintRoutingEditor(
      initialGraph: viewModel.printRoutingGraphSetting,
      onGraphChanged: controller.onPrintRoutingGraphChanged,
    ),
  );
}
