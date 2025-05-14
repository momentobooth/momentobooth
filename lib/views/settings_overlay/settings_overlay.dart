import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
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
      builder: (_) {
        // As it doesn't look feasible to externally check if the Settings overlay is opened
        // (e.g. by inspecting `Navigator state), we make the Settings overlay able to close itself.
        bool control = !Platform.isMacOS, meta = Platform.isMacOS;
        return CallbackShortcuts(
          bindings: {
            SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): () => Navigator.of(context, rootNavigator: true).pop(),
          },
          child: FocusScope( // Without the FocusScope, nothing happens, I'm not exactly sure why.
            autofocus: true,
            child: SettingsOverlay(initialPage: initialPage),
          ),
        );
      },
      barrierDismissible: true,
    );
    if (context.mounted) context.read<ActivityMonitorController>().resume();
  }

}
