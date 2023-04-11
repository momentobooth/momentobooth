import 'dart:io';
import 'dart:math';

import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_bridge.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view_model.dart';
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
    router.push("/");
  }

  String get ffSendUrl => SettingsManagerBase.instance.settings.output.firefoxSendServerUrl;

  void onClickGetQR() {
    print("Requesting QR code");
    var file = File('assets/bitmap/sample-background.jpg');

    var stream = rustLibraryApi.ffsendUploadFile(filePath: file.path, hostUrl: ffSendUrl, downloadFilename: "MomentoBooth image.jpg");
    stream.listen((event) {
      if (event.isFinished) {
        print("Upload complete. Download URL: ${event.downloadUrl}");
      } else {
        print("${event.transferredBytes}/${event.totalBytes}");
      }
    }).onError((x) {
      print(x);
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
    final photoToPrint = PhotosManagerBase.instance.photos.first;
    final image = pw.MemoryImage(photoToPrint);
    const pageFormat = PdfPageFormat(100.0 * PdfPageFormat.mm, 150.0 * PdfPageFormat.mm);

    final doc = pw.Document(title: "MomentoBooth image");
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Transform.rotateBox(
          angle: 0.5*pi,
          child: pw.Image(image, fit: pw.BoxFit.contain, height: pageFormat.width, width: pageFormat.height),
        );
      })
    );

    await Printing.directPrintPdf(
        printer: selected,
        name: "MomentoBooth image",
        format: pageFormat,
        onLayout: (PdfPageFormat pageFormat) => doc.save()
    );
  }

}
