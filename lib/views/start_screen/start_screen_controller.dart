import 'package:loggy/loggy.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/start_screen/start_screen_view_model.dart';

class StartScreenController extends ScreenControllerBase<StartScreenViewModel> with UiLoggy, PrinterStatusDialogMixin<StartScreenViewModel> {

  // Initialization/Deinitialization

  StartScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  Future<void> onPressedContinue() async {
    await checkPrintersAndShowWarnings();
    router.go(ChooseCaptureModeScreen.defaultRoute);
  }

  void onPressedGallery() {
    router.push(GalleryScreen.defaultRoute);
  }

}
