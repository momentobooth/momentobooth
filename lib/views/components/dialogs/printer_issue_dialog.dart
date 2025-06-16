import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/models/printer_issue_type.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PrinterIssueDialog extends StatelessWidget {

  final String printerName;
  final PrinterIssueType issueType;
  final List<PrintJobState> stuckJobs;
  final String errorText;
  final VoidCallback onIgnorePressed;
  final VoidCallback onResumeQueuePressed;

  const PrinterIssueDialog({
    super.key,
    required this.printerName,
    required this.issueType,
    required this.stuckJobs,
    required this.errorText,
    required this.onIgnorePressed,
    required this.onResumeQueuePressed,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: issueType.getTitle(context),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            issueType.getBody1(context, printerName, errorText),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          if (stuckJobs.length == 1)
            Text(
              localizations.printerErrorStuckJob,
            ),
          if (stuckJobs.length > 1)
            Text(
              localizations.printerErrorStuckJobs(stuckJobs.length),
            ),
          if (stuckJobs.isNotEmpty)
            const SizedBox(height: 16.0),
          Lottie.asset(
            'assets/animations/Animation - 1709936404300.json',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            height: 200,
            frameRate: FrameRate.max,
          ),
          const SizedBox(height: 16.0),
          Text(
            issueType.getBody2(context),
          ),
        ],
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: localizations.printerErrorIgnoreButton,
          icon: LucideIcons.clockArrowUp,
          onPressed: onIgnorePressed,
        ),
        PhotoBoothFilledButton(
          title: localizations.printerErrorResumeQueueButton,
          icon: LucideIcons.stepForward,
          onPressed: onResumeQueuePressed,
        ),
      ],
      dialogType: ModalDialogType.warning,
    );
  }

}


@UseCase(name: 'No Ink', type: PrinterIssueDialog)
Widget printerIssueDialog(BuildContext context) {
  return PrinterIssueDialog(
    printerName: 'MyBrand MyPrinter 5000',
    issueType: context.knobs.list(label: 'Issue Type', initialOption: PrinterIssueType.noInk, options: PrinterIssueType.values),
    stuckJobs: const [],
    errorText: context.knobs.string(label: 'Error Text', initialValue: 'The printer is out of ink. Please replace the ink cartridge.'),
    onIgnorePressed: () {},
    onResumeQueuePressed: () {},
  );
}
