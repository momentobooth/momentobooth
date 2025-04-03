import 'package:auto_route/annotations.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

@RoutePage()
class SettingsScreen extends ScreenBase<SettingsScreenViewModel, SettingsScreenController, SettingsScreenView> {

  final SettingsPageKey initialPage;

  const SettingsScreen({super.key, this.initialPage = SettingsPageKey.project});

  @override
  SettingsScreenController createController({required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  SettingsScreenView createView({required SettingsScreenController controller, required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor, initialPage: initialPage);
  }

  @override
  SettingsScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return SettingsScreenViewModel(contextAccessor: contextAccessor);
  }

}
