import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/components/activity_monitor.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_controller.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view_model.dart';
import 'package:provider/provider.dart';

class SettingsOverlay extends ScreenBase<SettingsOverlayViewModel, SettingsOverlayController, SettingsOverlayView> {

  final SettingsPageKey initialPage;

  const SettingsOverlay({super.key, required this.initialPage});

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

  static Future<void> openDialog(BuildContext context, {SettingsPageKey initialPage = SettingsPageKey.project}) async {
    context.read<ActivityMonitorController>().pause();
    await showDialog(
      context: context,
      builder: (_) => SettingsOverlay(initialPage: initialPage),
      barrierDismissible: true,
    );
    if (context.mounted) context.read<ActivityMonitorController>().resume();
  }

}
