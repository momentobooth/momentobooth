import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PrintingErrorDialog extends StatelessWidget {

  /// Some sheets were sent to a printer before printing failed, so guests may get part of their prints.
  final bool partiallyPrinted;

  const PrintingErrorDialog({super.key, this.partiallyPrinted = false});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: localizations.printingErrorDialogTitle,
      dialogType: ModalDialogType.error,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(partiallyPrinted ? localizations.printingErrorDialogBodyTopPartial : localizations.printingErrorDialogBodyTop),
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

@UseCase(name: 'Printing error after some prints', type: PrintingErrorDialog)
Widget printingErrorDialogPartial(BuildContext context) {
  return PrintingErrorDialog(partiallyPrinted: true);
}
