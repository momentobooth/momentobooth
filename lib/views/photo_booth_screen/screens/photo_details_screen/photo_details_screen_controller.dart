import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/print_dialog.dart';
import 'package:momento_booth/views/components/dialogs/printing_error_dialog.dart';
import 'package:momento_booth/views/components/dialogs/qr_share_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_view_model.dart';
import 'package:path/path.dart' as path;

class PhotoDetailsScreenController extends ScreenControllerBase<PhotoDetailsScreenViewModel> {

  AutoSizeGroup actionButtonGroup = AutoSizeGroup();

  // Initialization/Deinitialization

  PhotoDetailsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickPrev() {
    router.pop();
  }

  void onClickGetQR() {
    viewModel.uploadPhotoToSend();
    showUserDialog(
      barrierDismissible: false,
      dialog: Observer(builder: (_) {
        return QrShareDialog(
          state: viewModel.uploadFailed
              ? ShareDialogState.error
              : viewModel.uploadProgress != null || viewModel.qrUrl == null
                  ? ShareDialogState.uploading
                  : ShareDialogState.uploaded,
          uploadProgress: (viewModel.uploadProgress ?? 0) * 100,
          qrText: viewModel.qrUrl,
          onDismiss: () => navigator.pop(),
          onRedoUpload: viewModel.uploadPhotoToSend,
        );
      }),
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
    showUserDialog(
      barrierDismissible: false,
      dialog: Observer(builder: (_) {
        return PrintDialog(
          onPrintPressed: (size, copies) {
            navigator.pop();
            onConfirmPrint(size, copies);
          },
          onCancel: () => navigator.pop(),
        );
      }),
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
