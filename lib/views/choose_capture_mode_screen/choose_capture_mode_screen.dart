import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_base.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

class ChooseCaptureModeScreen extends ScreenBase<ChooseCaptureModeScreenViewModel, ChooseCaptureModeScreenController, ChooseCaptureModeScreenView> {

  const ChooseCaptureModeScreen({super.key});

  @override
  ChooseCaptureModeScreenController createController({required ChooseCaptureModeScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ChooseCaptureModeScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  ChooseCaptureModeScreenView createView({required ChooseCaptureModeScreenController controller, required ChooseCaptureModeScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ChooseCaptureModeScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  ChooseCaptureModeScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return ChooseCaptureModeScreenViewModel(contextAccessor: contextAccessor);
  }

}
