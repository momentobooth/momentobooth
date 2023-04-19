import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_view.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

class ChooseCaptureModeScreen extends ScreenBase<ChooseCaptureModeScreenViewModel, ChooseCaptureModeScreenController, ChooseCaptureModeScreenView> {

  static const String defaultRoute = "/choose_capture_mode";

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
