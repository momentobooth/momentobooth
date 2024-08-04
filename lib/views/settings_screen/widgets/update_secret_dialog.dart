import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/modal_dialog.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

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
    return ModalDialog(
      title: "Update password/secret [${widget.secretName}]",
      dialogType: ModalDialogType.input,
      body: Column(
        children: [
          PasswordBox(
            placeholder: "Enter the new password/secret",
            revealMode: PasswordRevealMode.peekAlways,
            onChanged: (value) => _input = value,
          ),
        ],
      ),
      onDismiss: widget.onDismiss,
      actions: [
        PhotoBoothFilledButton(
          title: 'Cancel',
          icon: LucideIcons.ban,
          onPressed: widget.onDismiss,
        ),
        PhotoBoothFilledButton(
          title: 'Save',
          icon: LucideIcons.save,
          onPressed: () => widget.onSavePressed(_input),
        ),
      ],
    );
  }
}

@widgetbook.UseCase(
  name: 'Update Secret Dialog',
  type: UpdateSecretDialog,
)
Widget updateSecretDialog(BuildContext context) {
  return UpdateSecretDialog(
    secretName: 'My Secret',
    onDismiss: () {},
    onSavePressed: (_) {},
  );
}
