import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';

class StartScreenController extends ScreenControllerBase<StartScreenViewModel> {

  // Initialization/Deinitialization

  StartScreenController({required super.viewModel});

  // User interaction methods

  void onClickOnSinglePhoto() {
    print("Single photo!");
  }

  void onClickOnPhotoCollage() {
    print("Photo college!");
  }

  void onClickOnSettings() {
    print("Settings!");
  }

}
