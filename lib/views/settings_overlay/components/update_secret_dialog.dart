import 'package:fluent_ui/fluent_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class UpdateSecretDialog extends StatefulWidget {

  final String secretName;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSavePressed;

  const UpdateSecretDialog({
    super.key,
    required this.secretName,
    required this.onDismiss,
    required this.onSavePressed,
  });

  @override
  State<UpdateSecretDialog> createState() => _UpdateSecretDialogState();
}

class _UpdateSecretDialogState extends State<UpdateSecretDialog> {
  String _input = '';

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Change secret"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 0),
            child: Text('[${widget.secretName}]'),
          ),
          PasswordBox(
            placeholder: "Enter the new password/secret",
            revealMode: PasswordRevealMode.peekAlways,
            onChanged: (value) => _input = value,
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: widget.onDismiss,
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => widget.onSavePressed(_input),
          child: Text('Save'),
        ),
      ],
    );
  }
}

@UseCase(name: 'Update Secret Dialog', type: UpdateSecretDialog)
Widget updateSecretDialog(BuildContext context) {
  return UpdateSecretDialog(
    secretName: 'My Secret',
    onDismiss: () {},
    onSavePressed: (_) {},
  );
}
