import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/share_screen/share_screen_view_model.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ShareScreenController extends ScreenControllerBase<ShareScreenViewModel> {

  // Initialization/Deinitialization

  ShareScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickNext() {
    router.go(StartScreen.defaultRoute);
  }
  
  void onClickPrev() {
    print("clicking prev");
    if (PhotosManagerBase.instance.captureMode == CaptureMode.single) {
      PhotosManagerBase.instance.reset(advance: false);
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

    print("Requesting QR code");
    final Uint8List imageData = PhotosManagerBase.instance.outputImage!;
    final Directory tempDir = await getTemporaryDirectory();
    final ext = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();
    File file = await File('${tempDir.path}/image.$ext').create();
    await file.writeAsBytes(imageData);

    var stream = rustLibraryApi.ffsendUploadFile(filePath: file.path, hostUrl: ffSendUrl, downloadFilename: "MomentoBooth image.$ext");
    viewModel.qrText = "Uploading";
    viewModel.uploadState = UploadState.uploading;
    stream.listen((event) {
      if (event.isFinished) {
        print("Upload complete. Download URL: ${event.downloadUrl}");
        viewModel.uploadState = UploadState.done;
        viewModel.qrText = "Show QR";
        viewModel.qrUrl = event.downloadUrl!;
        viewModel.qrShown = true;
        viewModel.sliderKey.currentState!.animateForward();
      } else {
        print("${event.transferredBytes}/${event.totalBytes}");
      }
    }).onError((x) {
      print(x);
      viewModel.uploadState = UploadState.errored;
    });
  }

  Future<void> onClickPrint() async {
    print("Requesting photo print");
    // Find printer that was set in settings in available printers.
    final printers = await Printing.listPrinters();
    Printer? selected;
    for (var printer in printers) {
      if (printer.name == SettingsManagerBase.instance.settings.hardware.printerName) {
        selected = printer;
        break;
      }
    }
    if (selected == null) {
      print("Could not find set printer");
      return;
    }

    // Get photo and print it.
    final photoToPrint = PhotosManagerBase.instance.outputImage!;
    final image = pw.MemoryImage(photoToPrint);
    const pageFormat = PdfPageFormat(100.0 * PdfPageFormat.mm, 150.0 * PdfPageFormat.mm);
    const fit = pw.BoxFit.contain;

    // Check if photo should be rotated
    // Do not assume any prior knowledge about the image.
    final bool rotate = image.width! > image.height!;
    late final pw.Image imageWidget;
    if (rotate) {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.width, width: pageFormat.height);
    } else {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.height, width: pageFormat.width);
    }

    final doc = pw.Document(title: "MomentoBooth image");
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return rotate ? pw.Transform.rotateBox(angle: 0.5*pi, child: imageWidget,) : imageWidget;
      })
    );

    bool success = await Printing.directPrintPdf(
        printer: selected,
        name: "MomentoBooth image",
        format: pageFormat,
        onLayout: (PdfPageFormat pageFormat) => doc.save()
    );

    viewModel.printText = success ? "Printing..." : "Print canceled";
    Future.delayed(Duration(seconds: 2), () => viewModel.printText = "Print");
  }

}
