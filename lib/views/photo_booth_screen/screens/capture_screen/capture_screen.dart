import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/capture_screen/capture_screen_view_model.dart';

class CaptureScreen extends ScreenBase<CaptureScreenViewModel, CaptureScreenController, CaptureScreenView> {

  static const String defaultRoute = "/capture";

  const CaptureScreen({super.key});

  @override
  CaptureScreenController createController({required CaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return CaptureScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  CaptureScreenView createView({required CaptureScreenController controller, required CaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return CaptureScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  CaptureScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return CaptureScreenViewModel(contextAccessor: contextAccessor);
  }

}
