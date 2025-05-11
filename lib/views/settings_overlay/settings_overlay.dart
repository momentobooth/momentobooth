import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_controller.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view_model.dart';

class SettingsOverlay extends ScreenBase<SettingsOverlayViewModel, SettingsOverlayController, SettingsOverlayView> {

  final SettingsPageKey initialPage;

  const SettingsOverlay({super.key, this.initialPage = SettingsPageKey.project});

  @override
  SettingsOverlayController createController({required SettingsOverlayViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsOverlayController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  SettingsOverlayView createView({required SettingsOverlayController controller, required SettingsOverlayViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsOverlayView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor, initialPage: initialPage);
  }

  @override
  SettingsOverlayViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return SettingsOverlayViewModel(contextAccessor: contextAccessor);
  }

  static void openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SettingsOverlay(),
      barrierDismissible: true,
    );
  }

}
