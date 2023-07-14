import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreen extends ScreenBase<SettingsScreenViewModel, SettingsScreenController, SettingsScreenView> {

  static const String defaultRoute = "/settings";

  const SettingsScreen({super.key});

  @override
  SettingsScreenController createController({required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  SettingsScreenView createView({required SettingsScreenController controller, required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  SettingsScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return SettingsScreenViewModel(contextAccessor: contextAccessor);
  }

}
