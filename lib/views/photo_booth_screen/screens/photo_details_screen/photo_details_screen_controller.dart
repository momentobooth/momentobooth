import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/exceptions/printing_exception.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/print_collected_dialog.dart';
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

  Future<void> onClickPrint() async {
    if (!viewModel.printEnabled) return;
    await showUserDialog(
      barrierDismissible: false,
      dialog: Observer(builder: (_) {
        return PrintDialog(
          isThreePhotoCollage: viewModel.isThreePhotoCollage ?? false,
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
    logDebug("Printing photo");

    viewModel
      ..printEnabled = false
      ..printText = localizations.photoDetailsScreenPrinting;

    String jobName = viewModel.file != null ? path.basenameWithoutExtension(viewModel.file!.path) : "MomentoBooth Reprint";

    bool success = false, partiallyPrinted = false;
    int waitingCopies = 0;
    try {
      waitingCopies = await getIt<PrintingManager>().printPhoto(jobName: jobName, image: await viewModel.file!.readAsBytes(), size: size, copies: copies);
      success = true;
    } catch (e, s) {
      logError("Failed to print photo", e, s);
      partiallyPrinted = e is PrintingException && e.sentSheets > 0;
    }

    successfulPrints += success ? copies : 0;
    if (!success) {
      unawaited(showUserDialog(dialog: PrintingErrorDialog(partiallyPrinted: partiallyPrinted), barrierDismissible: true));
    } else if (waitingCopies > 0) {
      unawaited(showUserDialog(dialog: const PrintCollectedDialog(), barrierDismissible: true));
    }
    resetPrint();
  }

}
