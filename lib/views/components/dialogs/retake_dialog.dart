import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class RetakeDialog extends StatelessWidget {

  final VoidCallback onDelete;
  final VoidCallback onKeep;
  final VoidCallback onCancel;

  const RetakeDialog({super.key, required this.onDelete, required this.onKeep, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: localizations.shareScreenRetakeButton,
      dialogType: ModalDialogType.warning,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localizations.retakeDialogBody),
        ],
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: localizations.genericCancelButton,
          onPressed: onCancel,
        ),
        PhotoBoothFilledButton(
          title: localizations.retakeDialogKeepButton,
          icon: LucideIcons.save,
          onPressed: onKeep,
        ),
        PhotoBoothFilledButton(
          title: localizations.genericDeleteButton,
          icon: LucideIcons.trash,
          onPressed: onDelete,
        ),
      ],
    );
  }

}
