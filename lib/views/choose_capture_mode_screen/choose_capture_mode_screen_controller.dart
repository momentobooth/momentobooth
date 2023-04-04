import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

class ChooseCaptureModeScreenController extends ScreenControllerBase<ChooseCaptureModeScreenViewModel> {

  // Initialization/Deinitialization

  ChooseCaptureModeScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  void onClickOnSinglePhoto() {
    PhotosManagerBase.instance.captureMode = CaptureMode.single;
    router.push("/capture");
  }

  void onClickOnPhotoCollage() {
    PhotosManagerBase.instance.captureMode = CaptureMode.collage;
    router.push("/capture");
    //print("Photo college!");
  }

}
