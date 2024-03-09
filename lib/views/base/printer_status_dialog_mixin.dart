import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/printer_issue_type.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/printer_issue_dialog.dart';

mixin PrinterStatusDialogMixin<T extends ScreenViewModelBase> on ScreenControllerBase<T>, UiLoggy {

  Future<void> checkPrintersAndShowWarnings() async {
    List<String> printerIds = SettingsManager.instance.settings.hardware.printerNames;
    for (var printerId in printerIds) {
      try {
        IppPrinterState printerState = await rustLibraryApi.cupsGetPrinterState(printerId: printerId);

        if (printerState.state == PrinterState.Stopped) {
          await showUserDialog(
            PrinterIssueDialog(
              printerName: printerState.name,
              issueType: PrinterIssueType.fromPrinterState(printerState.stateReason),
              errorText: printerState.stateMessage,
              onResumeQueuePressed: () async {
                try {
                  await rustLibraryApi.cupsResumePrinter(printerId: printerId);
                } catch (e) {
                  loggy.debug("Failed to resume printer [$printerId] with error: $e");
                }
              },
            ),
          );
        } else {
          // If printer does not have any error, perhaps the print job is stuck
          List<PrintJobState> printJobs = await rustLibraryApi.cupsGetJobsStates(printerId: printerId);
        }

      } catch (e) {
        loggy.debug("Failed to query printer [$printerId] with error: $e");
      }
    }
  }

}
