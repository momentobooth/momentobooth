import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_view_model.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PhotoDetailsScreenController extends ScreenControllerBase<PhotoDetailsScreenViewModel> with UiLoggy {

  // Initialization/Deinitialization

  PhotoDetailsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickPrev() {
    router.pop();
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

    final Uint8List imageData = PhotosManagerBase.instance.outputImage!;
    final Directory tempDir = await getTemporaryDirectory();
    final ext = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();
    File file = await File('${tempDir.path}/image.$ext').create();
    await file.writeAsBytes(imageData);

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
      loggy.error("Could not find selected printer");
      viewModel.printText = "Print error";
      Future.delayed(_printTextDuration, resetPrint);
      return;
    }

    // Get photo and print it.
    final photoToPrint = PhotosManagerBase.instance.outputImage!;
    final image = pw.MemoryImage(photoToPrint);
    const mm = PdfPageFormat.mm;
    final settings = SettingsManagerBase.instance.settings.hardware;
    final pageFormat = PdfPageFormat(settings.pageWidth * mm, settings.pageHeight * mm,
                                     marginBottom: settings.printerMarginBottom * mm,
                                     marginLeft: settings.printerMarginLeft * mm,
                                     marginRight: settings.printerMarginRight * mm,
                                     marginTop: settings.printerMarginTop * mm,);
    const fit = pw.BoxFit.contain;

    // Check if photo should be rotated
    // Do not assume any prior knowledge about the image.
    final bool rotate = image.width! > image.height!;
    late final pw.Image imageWidget;
    if (rotate) {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableWidth, width: pageFormat.availableHeight);
    } else {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableHeight, width: pageFormat.availableWidth);
    }

    final doc = pw.Document(title: "MomentoBooth image");
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Center(
          child: rotate ? pw.Transform.rotateBox(angle: 0.5*pi, child: imageWidget,) : imageWidget,
        );
      })
    );

    final pdfData = await doc.save();

    bool success = await Printing.directPrintPdf(
        printer: selected,
        name: "MomentoBooth image",
        format: pageFormat,
        onLayout: (PdfPageFormat pageFormat) => pdfData,
        usePrinterSettings: settings.usePrinterSettings,
    );
    StatsManagerBase.instance.addPrintedPhoto();

    Directory outputDir = Directory(SettingsManagerBase.instance.settings.output.localFolder);
    final filePath = join(outputDir.path, 'latest-print.pdf');
    File file = await File(filePath).create();
    await file.writeAsBytes(pdfData);

    viewModel.printText = success ? "Printing..." : "Print canceled";
    successfulPrints += success ? 1 : 0;
    Future.delayed(_printTextDuration, resetPrint);
  }

}
