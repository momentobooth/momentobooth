part of '../settings_overlay_view.dart';

Widget _getSubsystemStatusTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, BuildContext context) {
  return SettingsListPage(
    title: "Subsystem status",
    blocks: [
      SubsystemStatusList(),
      SettingsSection(
        title: "External System Health Checks",
        settings: [
          Observer(builder: (_) {
            return Column(
              children: [
                SettingsNumberEditTile(
                  icon: FluentIcons.clock,
                  title: "Check interval (seconds)",
                  subtitle: "How often to run external system health checks.",
                  value: () => viewModel.externalSystemCheckIntervalSeconds,
                  onFinishedEditing: (v) => controller.onExternalSystemCheckIntervalChanged(v),
                ),
                for (final (index, status) in getIt<ExternalSystemStatusManager>().systems.indexed)
                  ExternalSystemCheckTile(
                    sysStatus: status,
                    onEdit: (updated) {
                      final checks = [...viewModel.externalSystemChecks];
                      checks[index] = updated;
                      controller.onExternalSystemChecksChanged(checks);
                    },
                    onDelete: () {
                      final checks = [...viewModel.externalSystemChecks]..remove(status.check);
                      controller.onExternalSystemChecksChanged(checks);
                    },
                  ),
                SizedBox(height: 16),
                FilledButton(
                  child: const Text("+ Add check"),
                  onPressed: () {
                    // Show dialog to add new check
                    showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) => ExternalSystemCheckEditDialog(
                        onSave: (newCheck) {
                          final checks = [...viewModel.externalSystemChecks, newCheck];
                          controller.onExternalSystemChecksChanged(checks);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        ],
      ),
    ],
  );
}
