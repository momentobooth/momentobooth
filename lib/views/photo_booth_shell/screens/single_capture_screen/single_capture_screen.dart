import 'package:auto_route/annotations.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/single_capture_screen/single_capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/single_capture_screen/single_capture_screen_view.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/single_capture_screen/single_capture_screen_view_model.dart';

@RoutePage()
class SingleCaptureScreen extends ScreenBase<SingleCaptureScreenViewModel, SingleCaptureScreenController, SingleCaptureScreenView> {

  const SingleCaptureScreen({super.key});

  @override
  SingleCaptureScreenController createController({required SingleCaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SingleCaptureScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  SingleCaptureScreenView createView({required SingleCaptureScreenController controller, required SingleCaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SingleCaptureScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  SingleCaptureScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return SingleCaptureScreenViewModel(contextAccessor: contextAccessor);
  }

}
