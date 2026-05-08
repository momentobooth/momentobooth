import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/models/app_action_call.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/speech_phrases.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/print_dialog.dart';
import 'package:momento_booth/views/components/dialogs/printing_error_dialog.dart';
import 'package:momento_booth/views/components/dialogs/qr_share_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_view_model.dart';
import 'package:path/path.dart' as path;

class PhotoDetailsScreenController extends ScreenControllerBase<PhotoDetailsScreenViewModel> {

  AutoSizeGroup actionButtonGroup = AutoSizeGroup();

  @override
  String get scopeName => "Photo Details Screen";

  @override
  List<AppAction> get actions => [
    AppAction(
      name: "back",
      callback: (_, response) { onClickPrev(); response(true, "Back button pressed"); },
      title: "Back",
      description: "Return to the gallery screen.",
      examples: backPhrases
    ),
    AppAction(
      name: "get_qr",
      callback: (_, response) { onClickGetQR(); response(true, "Uploading the picture to get a QR code"); },
      title: "Get QR Code",
      description: "Generate a QR code for sharing the photo.",
      examples: getQRPhrases
    ),
    AppAction(
      name: "open_print_dialog",
      callback: (_, response) { onClickPrint(); response(true, "Opening the print dialog"); },
      title: "Print",
      description: "Open the print dialog.",
      examples: printPhrases
    ),
  ];

  // Initialization/Deinitialization

  PhotoDetailsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickPrev() {
    registerActionCall(const AppActionCall(tool: "back"));
    router.pop();
  }

  void onClickGetQR() {
    registerActionCall(const AppActionCall(tool: "get_qr"));
    if (viewModel.file == null) {
      logError("File is null when trying to get QR code");
      return;
    }
    final actionsToken = Object();
    showUserDialog(
      barrierDismissible: false,
      dialog: QrShareDialog(
        file: viewModel.file!,
        onDismiss: () => navigator.pop(),
        actionsToken: actionsToken,
      ),
      publishActions: false,
    );
  }

  int successfulPrints = 0;

  void resetPrint() {
    if (!contextAccessor.buildContext.mounted) return;
    viewModel
      ..printText = successfulPrints > 0 ? "${localizations.genericPrintButton} ↺" : localizations.genericPrintButton
      ..printEnabled = true;
  }

  void onClickPrint() {
    if (!viewModel.printEnabled) return;
    registerActionCall(const AppActionCall(tool: "open_print_dialog"));
    showUserDialog(
      barrierDismissible: false,
      dialog: PrintDialog(
        onPrintPressed: (size, copies) {
          navigator.pop();
          onConfirmPrint(size, copies);
        },
        onCancel: () => navigator.pop(),
      ),
      publishActions: false,
    );
  }

  Future<void> onConfirmPrint(PrintSize size, int copies) async {
    final imgSources = await viewModel.makerNoteData;
    final sourceCount = imgSources?.sourcePhotos.length;
    PrintSize usingSize = size;
    if (size == PrintSize.normal && sourceCount == 3) {
      usingSize = PrintSize.split;
    }

    logDebug("Printing photo");

    viewModel
      ..printEnabled = false
      ..printText = localizations.photoDetailsScreenPrinting;

    // Get photo and print it.
    final pdfData = await getImagePdfWithPageSize(await viewModel.file!.readAsBytes(), usingSize);
    String jobName = viewModel.file != null ? path.basenameWithoutExtension(viewModel.file!.path) : "MomentoBooth Reprint";

    bool success = false;
    try {
      await getIt<PrintingManager>().printPdf(jobName, pdfData, copies: copies, printSize: usingSize);
      success = true;
    } catch (e, s) {
      logError("Failed to print photo", e, s);
    }

    successfulPrints += success ? copies : 0;
    if (!success) unawaited(showUserDialog(dialog: const PrintingErrorDialog(), barrierDismissible: true));
    resetPrint();
  }

}
