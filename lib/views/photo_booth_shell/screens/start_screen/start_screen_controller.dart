import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/router.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/no_project_open_dialog.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/start_screen/start_screen_view_model.dart';

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

  void onPressedContinue() {
    router.navigate(ChooseCaptureModeRoute());
  }

  void onPressedGallery() {
    router.push(GalleryRoute());
  }

}
