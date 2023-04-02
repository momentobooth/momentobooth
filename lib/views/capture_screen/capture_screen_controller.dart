import 'package:flutter_rust_bridge_example/utils/sony_remote_photo_capture.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';

class CaptureScreenController extends ScreenControllerBase<CaptureScreenViewModel> {

  // Initialization/Deinitialization

  CaptureScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void captureAndGetPhoto() async {
    final capturer = SonyRemotePhotoCapture(r"C:\Users\caspe\Pictures");
    final image = await capturer.captureAndGetPhoto();
    print("Captured photo using AutoIT");
  }

}
