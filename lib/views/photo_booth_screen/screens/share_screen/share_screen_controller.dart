import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/managers/sfx_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/print_dialog.dart';
import 'package:momento_booth/views/components/dialogs/printing_error_dialog.dart';
import 'package:momento_booth/views/components/dialogs/qr_share_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:path/path.dart' as path;

class ShareScreenController extends ScreenControllerBase<ShareScreenViewModel> with PrinterStatusDialogMixin<ShareScreenViewModel> {

  AutoSizeGroup actionButtonGroup = AutoSizeGroup(), navigationButtonGroup = AutoSizeGroup();

  // Initialization/Deinitialization

  ShareScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    getIt<SfxManager>().playShareScreenSound();
  }

  void onClickNext() {
    router.go(StartScreen.defaultRoute);
  }

  void onClickPrev() {
    logDebug("Clicked prev");
    if (getIt<PhotosManager>().captureMode == CaptureMode.single) {
      getIt<PhotosManager>().reset(advance: false);
      getIt<StatsManager>().addRetake();
      router.go(SingleCaptureScreen.defaultRoute);
    } else {
      getIt<StatsManager>().addCollageChange();
      router.go(CollageMakerScreen.defaultRoute);
    }
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
      ..printText = successfulPrints > 0 ? "${localizations.genericPrintButton} +1" : localizations.genericPrintButton
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
    PrintSize usingSize = size;
    if (size == PrintSize.normal && getIt<PhotosManager>().chosenPhotos.length == 3) {
      usingSize = PrintSize.split;
    }

    logDebug("Printing photo");

    viewModel
      ..printEnabled = false
      ..printText = localizations.shareScreenPrinting;

    // Get photo and print it.
    final pdfData = await getIt<PhotosManager>().getOutputPDF(size);
    String jobName = viewModel.file != null ? path.basenameWithoutExtension(viewModel.file!.path) : "MomentoBooth Picture";

    bool success = false;
    try {
      await getIt<PrintingManager>().printPdf(jobName, pdfData, copies: copies, printSize: usingSize);
      success = true;
    } catch (e) {
      logError("Failed to print photo: $e");
    }

    successfulPrints += success ? copies : 0;
    if (!success) unawaited(showUserDialog(dialog: const PrintingErrorDialog(), barrierDismissible: true));
    resetPrint();

    await checkPrintersAndShowWarnings();
  }

}
