import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/share_screen/share_screen_view_model.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';

class ShareScreenController extends ScreenControllerBase<ShareScreenViewModel> with UiLoggy {

  // Initialization/Deinitialization

  ShareScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickNext() {
    router.go(StartScreen.defaultRoute);
  }
  
  void onClickPrev() {
    loggy.debug("Clicked prev");
    if (PhotosManagerBase.instance.captureMode == CaptureMode.single) {
      PhotosManagerBase.instance.reset(advance: false);
      StatsManagerBase.instance.addRetake();
      router.go(CaptureScreen.defaultRoute);
    } else {
      router.go(CollageMakerScreen.defaultRoute);
    }
  }

  String get ffSendUrl => SettingsManagerBase.instance.settings.output.firefoxSendServerUrl;

  void onClickCloseQR() {
    viewModel.qrShown = false;
    viewModel.sliderKey.currentState!.animateBackward();
  }
  
  void onClickGetQR() async {
    if (viewModel.uploadState == UploadState.done) {
      viewModel.qrShown = true;
      viewModel.sliderKey.currentState!.animateForward();
    }
    if (viewModel.uploadState != UploadState.notStarted) return;

    File file = await PhotosManagerBase.instance.getOutputImageAsTempFile();
    final ext = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();

    loggy.debug("Uploading ${file.path}");
    var stream = rustLibraryApi.ffsendUploadFile(filePath: file.path, hostUrl: ffSendUrl, downloadFilename: "MomentoBooth image.$ext");
    viewModel.qrText = "Uploading";
    viewModel.uploadState = UploadState.uploading;
    stream.listen((event) {
      if (event.isFinished) {
        loggy.debug("Upload complete: ${event.downloadUrl}");
        viewModel.uploadState = UploadState.done;
        viewModel.qrText = "Show QR";
        viewModel.qrUrl = event.downloadUrl!;
        viewModel.qrShown = true;
        viewModel.sliderKey.currentState!.animateForward();
        StatsManagerBase.instance.addUploadedPhoto();
      } else {
        loggy.debug("Uploading: ${event.transferredBytes}/${event.totalBytes} bytes");
      }
    }).onError((x) {
      loggy.error("Upload failed, file path: ${file.path}", x);
      viewModel.uploadState = UploadState.errored;
    });
  }

  int successfulPrints = 0;
  static const _printTextDuration = Duration(seconds: 4);

  void resetPrint() {
    viewModel.printText = successfulPrints > 0 ? "Print +1" : "Print";
    viewModel.printEnabled = true;
  }

  Future<void> onClickPrint() async {
    if (!viewModel.printEnabled) return;

    loggy.debug("Printing photo");
    viewModel.printEnabled = false;
    viewModel.printText = "Printing...";
    
    // Get photo and print it.
    final pdfData = await PhotosManagerBase.instance.getOutputPDF();
    final bool success = await printPDF(pdfData);

    viewModel.printText = success ? "Printing..." : "Print unsuccessful";
    successfulPrints += success ? 1 : 0;
    Future.delayed(_printTextDuration, resetPrint);
  }

}
