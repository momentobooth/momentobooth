import 'dart:async';

import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/managers/sfx_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/print_dialog.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/qr_share_dialog.dart';
import 'package:momento_booth/views/share_screen/share_screen_view_model.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';
import 'package:path/path.dart' as path;

class ShareScreenController extends ScreenControllerBase<ShareScreenViewModel> with PrinterStatusDialogMixin<ShareScreenViewModel> {

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
    if (PhotosManager.instance.captureMode == CaptureMode.single) {
      PhotosManager.instance.reset(advance: false);
      getIt<StatsManager>().addRetake();
      router.go(CaptureScreen.defaultRoute);
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
  static const _printTextDuration = Duration(seconds: 4);

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
    if (size == PrintSize.normal && PhotosManager.instance.chosenPhotos.length == 3) {
      usingSize = PrintSize.split;
    }

    logDebug("Printing photo");

    viewModel
      ..printEnabled = false
      ..printText = localizations.shareScreenPrinting;

    // Get photo and print it.
    final pdfData = await PhotosManager.instance.getOutputPDF(size);
    String jobName = viewModel.file != null ? path.basenameWithoutExtension(viewModel.file!.path) : "MomentoBooth Picture";

    bool success = false;
    try {
      await getIt<PrintingManager>().printPdf(jobName, pdfData, copies: copies, printSize: usingSize);
      success = true;
    } catch (e) {
      logError("Failed to print photo: $e");
    }

    viewModel.printText = success ? localizations.shareScreenPrinting : localizations.shareScreenPrintUnsuccesful;
    successfulPrints += success ? copies : 0;
    Future.delayed(_printTextDuration, resetPrint);

    await checkPrintersAndShowWarnings();
  }

}
