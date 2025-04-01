import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/photo_booth_shell.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';

class ChooseCaptureModeScreenController extends ScreenControllerBase<ChooseCaptureModeScreenViewModel> {

  // Initialization/Deinitialization

  ChooseCaptureModeScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  void onClickOnSinglePhoto() {
    getIt<PhotosManager>().captureMode = CaptureMode.single;
    router.go(const SingleCaptureRoute().location);
  }

  void onClickOnPhotoCollage() {
    getIt<PhotosManager>().captureMode = CaptureMode.collage;
    router.go(MultiCaptureRoute().location);
  }

}
