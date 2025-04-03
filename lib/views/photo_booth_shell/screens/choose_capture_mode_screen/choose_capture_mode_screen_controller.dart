import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/router.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

class ChooseCaptureModeScreenController extends ScreenControllerBase<ChooseCaptureModeScreenViewModel> {

  // Initialization/Deinitialization

  ChooseCaptureModeScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  void onClickOnSinglePhoto() {
    getIt<PhotosManager>().captureMode = CaptureMode.single;
    router.replaceAll([SingleCaptureRoute()]);
  }

  void onClickOnPhotoCollage() {
    getIt<PhotosManager>().captureMode = CaptureMode.collage;
    router.replaceAll([MultiCaptureRoute()]);
  }

}
