import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_controller.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_view_model.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_view.dart';

class InitializationScreen extends ScreenBase<InitializationScreenViewModel, InitializationScreenController, InitializationScreenView> {

  static const String defaultRoute = "/";

  const InitializationScreen({super.key});

  @override
  InitializationScreenController createController({required InitializationScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return InitializationScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  InitializationScreenView createView({required InitializationScreenController controller, required InitializationScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return InitializationScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  InitializationScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return InitializationScreenViewModel(contextAccessor: contextAccessor);
  }

}
