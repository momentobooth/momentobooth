import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen_view_model.dart';

class SingleCaptureScreenController extends ScreenControllerBase<SingleCaptureScreenViewModel> {

  // Initialization/Deinitialization

  SingleCaptureScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    getIt<PhotosManager>().captureMode = CaptureMode.single;
  }

}
