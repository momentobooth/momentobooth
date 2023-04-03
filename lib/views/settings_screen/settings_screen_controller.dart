import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreenController extends ScreenControllerBase<SettingsScreenViewModel> {

  // Initialization/Deinitialization

  SettingsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onNavigationPaneIndexChanged(int newIndex) {
    viewModel.paneIndex = newIndex;
  }

}
