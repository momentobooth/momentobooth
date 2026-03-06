import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_icon.dart';
import 'package:momento_booth/views/settings_overlay/components/external_system_check_edit_dialog.dart';

class ExternalSystemCheckTile extends StatefulWidget {

  final ExternalSystemStatus sysStatus;
  final ValueChanged<ExternalSystemCheckSetting> onEdit;
  final VoidCallback onDelete;

  const ExternalSystemCheckTile({super.key, required this.sysStatus, required this.onEdit, required this.onDelete});

  @override
  State<ExternalSystemCheckTile> createState() => _ExternalSystemCheckTileState();

}

class _ExternalSystemCheckTileState extends State<ExternalSystemCheckTile> {

  DateFormat get _dateFormat => DateFormat('HH:mm:ss');
  SubsystemStatus get _status => widget.sysStatus.isHealthy;
  ExternalSystemCheckSetting get _check => widget.sysStatus.check;
  bool get _loading => widget.sysStatus.inProgress;
  SubsystemStatus get _statusIconData => _status;
  bool _isExpanded = false;

  String? get _exception => switch (_status) {
        SubsystemStatusError(:final message, :final exception) => 'Error: $message${_isExpanded ? '\n\nException: $exception' : ' (click to expand for details)'}',
        SubsystemStatusWarning(:final message, :final exception) => 'Error: $message${_isExpanded ? '\n\nException: $exception' : ' (click to expand for details)'}',
        _ => null,
      };

  String? get _successMessage => switch (_status) {
        SubsystemStatusOk(:final message) => 'Success${_isExpanded ? '\n\nDetails: $message' : ' (click to expand for details)'}',
        _ => null,
      };

  Future<void> _refreshStatus() async {
    await getIt<ExternalSystemStatusManager>().runCheck(_check);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
        leading: Row(
          children: [
            SubsystemStatusIcon(status: _statusIconData),
            SizedBox(width: 6), // Add some spacing between icon and text
          ],
        ),
        title: Text(_check.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_check.type.name.toUpperCase()} to ${_check.address} · Last update: ${_dateFormat.format(widget.sysStatus.timestamp)}'),
            if (_exception != null)
              Text('$_exception', style: TextStyle(color: Colors.red))
            else if (_successMessage != null)
              Text('$_successMessage', style: TextStyle(color: Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Tooltip(
              message: 'Enable/Disable',
              child: ToggleSwitch(
                checked: _check.enabled,
                onChanged: (v) => widget.onEdit(_check.copyWith(enabled: v)),
              )
            ),
            SizedBox(width: 2),
            Tooltip(
              message: 'Refresh',
              child: IconButton(
                icon: _loading
                    ? SizedBox.square(dimension: 20, child: const ProgressRing(strokeWidth: 3))
                    : const Icon(FluentIcons.refresh),
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
                    builder: (context) => ExternalSystemCheckEditDialog(
                      initial: _check,
                      onSave: (updated) {
                        widget.onEdit(updated);
                        Navigator.of(context).pop();
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
