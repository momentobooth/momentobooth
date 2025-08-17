part of '../settings_overlay_view.dart';

Widget _getSubsystemStatusTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, BuildContext context) {
  return SettingsPage(
    title: "Subsystem status",
    blocks: [
      SubsystemStatusList(),
      SettingsSection(
        title: "External System Health Checks",
        settings: [
          Observer(builder: (_) {
            return Column(
              children: [
                for (final check in viewModel.externalSystemChecks)
                  _ExternalSystemCheckTile(
                    check: check,
                    onEdit: (updated) {
                      final checks = [...viewModel.externalSystemChecks];
                      final idx = checks.indexOf(check);
                      if (idx != -1) {
                        checks[idx] = updated;
                        controller.onExternalSystemChecksChanged(checks);
                      }
                    },
                    onDelete: () {
                      final checks = [...viewModel.externalSystemChecks]..remove(check);
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
                      builder: (ctx) => _ExternalSystemCheckEditDialog(
                        onSave: (newCheck) {
                          final checks = [...viewModel.externalSystemChecks, newCheck];
                          controller.onExternalSystemChecksChanged(checks);
                          Navigator.of(ctx).pop();
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

class _ExternalSystemCheckTile extends StatefulWidget {
  final ExternalSystemCheckSetting check;
  final ValueChanged<ExternalSystemCheckSetting> onEdit;
  final VoidCallback onDelete;

  const _ExternalSystemCheckTile({required this.check, required this.onEdit, required this.onDelete});

  @override
  State<_ExternalSystemCheckTile> createState() => _ExternalSystemCheckTileState();
}

class _ExternalSystemCheckTileState extends State<_ExternalSystemCheckTile> {
  ExternalSystemStatus? _status;
  bool _loading = false;

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final manager = ExternalSystemStatusManager([
      ExternalSystemCheck(
        name: widget.check.name,
        address: widget.check.address,
        type: widget.check.type == ExternalSystemCheckType.ping
            ? ExternalSystemCheckType.ping
            : ExternalSystemCheckType.http,
      ),
    ]);
    final statuses = await manager.runAllChecks();
    setState(() {
      _status = statuses.first;
      _loading = false;
    });
  }

  SubsystemStatus get _statusIconData {
    if (_status == null) return const SubsystemStatus.initial();
    return _status?.isHealthy == true
      ? const SubsystemStatus.ok()
      : SubsystemStatus.error(message: _status?.error ?? "Unknown error");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: SubsystemStatusIcon(status: _statusIconData),
        title: Text(widget.check.name),
        subtitle: Text('${widget.check.type.name.toUpperCase()} - ${widget.check.address}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Enable/Disable',
              child: ToggleSwitch(
                checked: widget.check.enabled,
                onChanged: (v) => setState(() => widget.onEdit(widget.check.copyWith(enabled: v))),
              )
            ),
            Tooltip(
              message: 'Refresh',
              child: IconButton(
                icon: _loading ? SizedBox.square(dimension: 20 , child: const ProgressRing(strokeWidth: 3,)) : const Icon(FluentIcons.refresh),
                onPressed: _loading ? null : _refreshStatus,
              ),
            ),
            Tooltip(
              message: 'Edit',
              child: IconButton(
                icon: const Icon(FluentIcons.edit),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (ctx) => _ExternalSystemCheckEditDialog(
                      initial: widget.check,
                      onSave: (updated) {
                        widget.onEdit(updated);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            Tooltip(
              message: 'Delete',
              child: IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalSystemCheckEditDialog extends StatefulWidget {
  final ExternalSystemCheckSetting? initial;
  final ValueChanged<ExternalSystemCheckSetting> onSave;

  const _ExternalSystemCheckEditDialog({this.initial, required this.onSave});

  @override
  State<_ExternalSystemCheckEditDialog> createState() => _ExternalSystemCheckEditDialogState();
}

class _ExternalSystemCheckEditDialogState extends State<_ExternalSystemCheckEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  ExternalSystemCheckType _type = ExternalSystemCheckType.ping;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _addressController = TextEditingController(text: widget.initial?.address ?? '');
    _type = widget.initial?.type ?? ExternalSystemCheckType.ping;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('External System Check'),
      content: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text('Name', style: FluentTheme.of(context).typography.bodyStrong),
              ),
              Expanded(
                flex: 2,
                child: TextBox(
                  controller: _nameController,
                  placeholder: 'Name',
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text('Address', style: FluentTheme.of(context).typography.bodyStrong),
              ),
              Expanded(
                flex: 2,
                child: TextBox(
                  controller: _addressController,
                  placeholder: 'Address (IP/hostname or URL)',
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text('Type', style: FluentTheme.of(context).typography.bodyStrong),
              ),
              Expanded(
                flex: 2,
                child: ComboBox<ExternalSystemCheckType>(
                  value: _type,
                  items: ExternalSystemCheckType.values
                      .map((t) => ComboBoxItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t ?? ExternalSystemCheckType.ping),
                  // header: 'Type',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          child: const Text('Save'),
          onPressed: () {
            widget.onSave(
              ExternalSystemCheckSetting(
                name: _nameController.text,
                address: _addressController.text,
                type: _type,
              ),
            );
          },
        ),
      ],
    );
  }
}
