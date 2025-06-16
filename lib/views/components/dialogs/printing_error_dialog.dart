import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PrintingErrorDialog extends StatelessWidget {

  const PrintingErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: localizations.printingErrorDialogTitle,
      dialogType: ModalDialogType.error,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localizations.printingErrorDialogBodyTop),
          const SizedBox(height: 16.0),
          Lottie.asset(
            'assets/animations/Animation - 1709936404300.json',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            height: 200,
            frameRate: FrameRate.max,
          ),
          const SizedBox(height: 16.0),
          Text(localizations.printingErrorDialogBodyBottom),
        ],
      ),
    );
  }

}

@UseCase(name: 'Printing error', type: PrintingErrorDialog)
Widget printingErrorDialog(BuildContext context) {
  return PrintingErrorDialog();
}
