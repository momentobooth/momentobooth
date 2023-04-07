import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view_model.dart';
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

  void onClickGetQR() {
    print("Requesting QR code");
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
    await Printing.directPrintPdf(
        printer: selected, name: "MomentoBooth image", onLayout: (_) => photoToPrint);
  }

}
