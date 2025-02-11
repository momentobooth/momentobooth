part of '../settings_screen_view.dart';

Widget _getSubsystemStatusTab(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Subsystem status",
    blocks: [SubsystemStatusList()],
  );
}
