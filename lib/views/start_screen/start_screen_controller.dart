import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';

class StartScreenController extends ScreenControllerBase<StartScreenViewModel> {

  // Initialization/Deinitialization

  StartScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  void onPressedContinue() {
    router.push(ChooseCaptureModeScreen.defaultRoute);
  }

}
