import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/no_project_open_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view_model.dart';

class StartScreenController extends ScreenControllerBase<StartScreenViewModel> with PrinterStatusDialogMixin<StartScreenViewModel> {

  // Initialization/Deinitialization

  StartScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) => noProjectOpenedDialog());
  }

  Future<void> noProjectOpenedDialog() async {
    if (!getIt<ProjectManager>().isOpen) {
      await showUserDialog(
        dialog: NoProjectOpenDialog(onOpened: () { navigator.pop(); },), barrierDismissible: false,
      );
    }
  }

  // User interaction methods

  Future<void> onPressedContinue() async {
    final singleCapture = getIt<ProjectManager>().settings.enableSingleCapture;
    final collageCapture = getIt<ProjectManager>().settings.enableCollageCapture;
    if (singleCapture && collageCapture) {
      router.go(ChooseCaptureModeScreen.defaultRoute);
      return;
    } else if (singleCapture) {
      router.go(SingleCaptureScreen.defaultRoute);
      return;
    } else if (collageCapture) {
      router.go(MultiCaptureScreen.defaultRoute);
      return;
    } else {
      // This should never happen, but just in case
      await showUserDialog(
        dialog: ContentDialog(
          title: const Text("No capture modes enabled"),
          content: const Text("No capture modes are enabled in the project settings. Please enable at least one capture mode to continue."),
          actions: [
            Button(
              child: const Text("OK"),
              onPressed: () { navigator.pop(); },
            ),
          ],
        ), barrierDismissible: false,
      );
    }
  }

  void onPressedGallery() {
    router.push(GalleryScreen.defaultRoute);
  }

}
