import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/models/settings.dart';

class ExternalSystemCheckEditDialog extends StatefulWidget {

  final ExternalSystemCheckSetting? initial;
  final ValueChanged<ExternalSystemCheckSetting> onSave;

  const ExternalSystemCheckEditDialog({super.key, this.initial, required this.onSave});

  @override
  State<ExternalSystemCheckEditDialog> createState() => _ExternalSystemCheckEditDialogState();

}

class _ExternalSystemCheckEditDialogState extends State<ExternalSystemCheckEditDialog> {

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  ExternalSystemCheckType _type = ExternalSystemCheckType.ping;
  ExternalSystemCheckSeverity _severity = ExternalSystemCheckSeverity.warning;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _addressController = TextEditingController(text: widget.initial?.address ?? '');
    _type = widget.initial?.type ?? _type;
    _severity = widget.initial?.severity ?? _severity;
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
                child: TextBox(controller: _nameController, placeholder: 'Name'),
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
                child: TextBox(controller: _addressController, placeholder: 'Address (IP/hostname or URL)'),
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
                  isExpanded: true,
                  value: _type,
                  items: ExternalSystemCheckType.values
                      .map((t) => ComboBoxItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t ?? ExternalSystemCheckType.ping),
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text('Severity', style: FluentTheme.of(context).typography.bodyStrong),
              ),
              Expanded(
                flex: 2,
                child: ComboBox<ExternalSystemCheckSeverity>(
                  isExpanded: true,
                  value: _severity,
                  items: ExternalSystemCheckSeverity.values
                      .map((t) => ComboBoxItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (t) => setState(() => _severity = t ?? ExternalSystemCheckSeverity.warning),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Button(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        FilledButton(
          child: const Text('Save'),
          onPressed: () {
            widget.onSave(
              ExternalSystemCheckSetting(
                name: _nameController.text,
                address: _addressController.text,
                type: _type,
                severity: _severity,
              ),
            );
          },
        ),
      ],
    );
  }

}
