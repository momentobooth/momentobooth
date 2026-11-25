import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';

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

    return ContentDialog(
      title: const Text("Import settings"),
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Do you want to apply the following settings?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text("Items in bold are different from your current settings"),
          const SizedBox(height: 20.0),
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
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
                        Text("${update.path}: old=${update.oldValue} new=${update.newValue}", style: const TextStyle(fontWeight: FontWeight.bold))
                      else
                        Text("${update.path}: value=${update.newValue}")
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: onCancel,
          child: Text(localizations.genericCancelButton),
        ),
        FilledButton(
          onPressed: onAccept,
          child: const Text("Accept"),
        ),
      ],
    );
  }

}
