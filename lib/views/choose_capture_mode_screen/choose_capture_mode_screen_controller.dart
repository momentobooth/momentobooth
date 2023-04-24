import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/capture_screen/capture_screen.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen.dart';

class ChooseCaptureModeScreenController extends ScreenControllerBase<ChooseCaptureModeScreenViewModel> {

  // Initialization/Deinitialization

  ChooseCaptureModeScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  void onClickOnSinglePhoto() {
    PhotosManagerBase.instance.captureMode = CaptureMode.single;
    router.go(CaptureScreen.defaultRoute);
  }

  void onClickOnPhotoCollage() {
    PhotosManagerBase.instance.captureMode = CaptureMode.collage;
    router.go(MultiCaptureScreen.defaultRoute);
  }

}
