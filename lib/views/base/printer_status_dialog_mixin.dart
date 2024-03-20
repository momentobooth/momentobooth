import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/printer_issue_type.dart';
import 'package:momento_booth/src/rust/api/cups.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/printer_issue_dialog.dart';

mixin PrinterStatusDialogMixin<T extends ScreenViewModelBase> on ScreenControllerBase<T>, UiLoggy {

  Future<void> checkPrintersAndShowWarnings() async {
    if (!Platform.isLinux) return;

    List<String> printerIds = SettingsManager.instance.settings.hardware.printerNames;
    for (var printerId in printerIds) {
      try {
        IppPrinterState printerState = await cupsGetPrinterState(printerId: printerId);

        if (printerState.state == PrinterState.stopped) {
          await showUserDialog(
            barrierDismissible: false,
            dialog: PrinterIssueDialog(
              printerName: printerState.name,
              issueType: PrinterIssueType.fromPrinterState(printerState.stateReason),
              errorText: printerState.stateMessage,
              onIgnorePressed: () => navigator.pop(),
              onResumeQueuePressed: () async {
                navigator.pop();
                try {
                  await cupsResumePrinter(printerId: printerId);
                } catch (e) {
                  loggy.debug("Failed to resume printer [$printerId] with error: $e");
                }
              },
            ),
          );
        }
      } catch (e) {
        loggy.debug("Failed to query printer [$printerId] with error: $e");
      }
    }
  }

}
