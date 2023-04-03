import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_base.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';

class StartScreen extends ScreenBase<StartScreenViewModel, StartScreenController, StartScreenView> {

  static const String defaultRoute = "/";

  const StartScreen({super.key});

  @override
  StartScreenController createController({required StartScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return StartScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  StartScreenView createView({required StartScreenController controller, required StartScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return StartScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  StartScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return StartScreenViewModel(contextAccessor: contextAccessor);
  }

}
