import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Tells guests that their print comes out later: it waits on a stack until a sheet is filled with the photos of other
/// guests.
class PrintCollectedDialog extends StatelessWidget {

  const PrintCollectedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      // The body is a single long text, which would otherwise stretch the dialog to its length.
      width: 600,
      title: localizations.printCollectedDialogTitle,
      body: Text(localizations.printCollectedDialogBody),
      autoDismissAfter: ModalDialog.guestInfoAutoDismissAfter,
    );
  }

}

@UseCase(name: 'Print comes later', type: PrintCollectedDialog)
Widget printCollectedDialog(BuildContext context) {
  return const PrintCollectedDialog();
}
