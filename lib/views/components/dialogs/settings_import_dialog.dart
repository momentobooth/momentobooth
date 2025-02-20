import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class SettingsImportDialog extends StatelessWidget {

  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final List<UpdateRecord> updates;

  const SettingsImportDialog({
    super.key,
    required this.onAccept,
    required this.onCancel,
    required this.updates,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: "Import settings",
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Do you want to apply the following settings?",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Items in bold are different from your current settings"),
          SizedBox(height: 20.0,),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[30],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final update in updates)
                    if (update.newValue != update.oldValue)
                      Text("${update.path}: old=${update.oldValue} new=${update.newValue}", style: TextStyle(fontWeight: FontWeight.bold))
                    else
                      Text("${update.path}: value=${update.newValue}")
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: localizations.genericCancelButton,
          onPressed: onCancel,
        ),
        PhotoBoothFilledButton(
          title: "Accept",
          icon: LucideIcons.check,
          onPressed: onAccept,
        ),
      ],
      dialogType: ModalDialogType.input,
    );
  }

}
