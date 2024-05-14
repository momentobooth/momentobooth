import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/qr_share_dialog.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_view_model.dart';
import 'package:path/path.dart' as path;

class PhotoDetailsScreenController extends ScreenControllerBase<PhotoDetailsScreenViewModel> {

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
  static const _printTextDuration = Duration(seconds: 4);

  void resetPrint() {
    if (!contextAccessor.buildContext.mounted) return;
    viewModel
      ..printText = successfulPrints > 0 ? "${localizations.genericPrintButton} +1" : localizations.genericPrintButton
      ..printEnabled = true;
  }

  Future<void> onClickPrint() async {
    if (!viewModel.printEnabled) return;

    logDebug("Printing photo");

    viewModel
      ..printEnabled = false
      ..printText = localizations.photoDetailsScreenPrinting;

    // Get photo and print it.
    final pdfData = await getImagePdfWithPageSize(await viewModel.file!.readAsBytes(), PrintSize.tiny);
    String jobName = viewModel.file != null ? path.basenameWithoutExtension(viewModel.file!.path) : "MomentoBooth Reprint";

    bool success = false;
    try {
      await PrintingManager.instance.printPdf(jobName, pdfData);
      success = true;
    } catch (e) {
      logError("Failed to print photo: $e");
    }

    viewModel.printText = success ? localizations.photoDetailsScreenPrinting : localizations.photoDetailsScreenPrintUnsuccesful;
    successfulPrints += success ? 1 : 0;
    Future.delayed(_printTextDuration, resetPrint);
  }

}
