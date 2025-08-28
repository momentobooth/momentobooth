// ignore_for_file: dead_code

import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/printer_issue_type.dart';
import 'package:momento_booth/src/rust/api/cups.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/utils/logging.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/dialogs/printer_issue_dialog.dart';

mixin PrinterStatusDialogMixin<T extends ScreenViewModelBase> on ScreenControllerBase<T> {

  Future<void> checkPrintersAndShowWarnings() async {
    return; // TODO: Remove this line when the feature is ready.

    List<String> printerIds = getIt<SettingsManager>().settings.hardware.cupsPrinterQueues;
    for (var printerId in printerIds) {
      try {
        // Verify printer ready.
        IppPrinterState printerState = await cupsGetPrinterState(serverInfo: CupsClient.serverInfo, queueId: printerId);
        List<PrintJobState> jobs = await cupsGetJobsStates(serverInfo: CupsClient.serverInfo, queueId: printerId);
        List<PrintJobState> stuckJobs = jobs.where((job) => job.state == JobState.pending || job.state == JobState.pendingHeld).toList();

        if (printerState.state == PrinterState.stopped || stuckJobs.isNotEmpty) {
          await _showDialog(printerState, printerId, stuckJobs);
        }
      } catch (e) {
        logDebug("Failed to query printer [$printerId] with error: $e");
      }
    }
  }

  Future<void> _showDialog(IppPrinterState printerState, String printerId, List<PrintJobState> stuckJobs) async {
    await showUserDialog(
      barrierDismissible: false,
      dialog: PrinterIssueDialog(
        printerName: printerState.description,
        issueType: PrinterIssueType.fromPrinterState(printerState.stateReason),
        stuckJobs: stuckJobs,
        errorText: printerState.stateMessage,
        onIgnorePressed: () => navigator.pop(),
        onResumeQueuePressed: () async {
          navigator.pop();

          try {
            await cupsResumePrinter(serverInfo: CupsClient.serverInfo, queueId: printerId);
          } catch (e) {
            logDebug("Failed to resume printer [$printerId] with error: $e");
          }

          for (PrintJobState job in stuckJobs) {
            try {
              await cupsReleaseJob(serverInfo: CupsClient.serverInfo, queueId: printerId, jobId: job.id);
            } catch (e) {
              logDebug("Failed to release stuck job [${job.name}] for printer [$printerId] with error: $e");
            }
          }
        },
      ),
    );
  }

}
