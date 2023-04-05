import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/multi_capture_screen/multi_capture_screen_view_model.dart';

class MultiCaptureScreenController extends ScreenControllerBase<MultiCaptureScreenViewModel> {

  // Initialization/Deinitialization

  MultiCaptureScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

}
