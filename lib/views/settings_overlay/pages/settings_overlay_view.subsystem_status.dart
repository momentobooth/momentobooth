part of '../settings_overlay_view.dart';

Widget _getSubsystemStatusTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "Subsystem status",
    blocks: [SubsystemStatusList()],
  );
}
