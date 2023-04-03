import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';

class CaptureScreen extends ScreenBase<CaptureScreenViewModel, CaptureScreenController, CaptureScreenView> {

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
