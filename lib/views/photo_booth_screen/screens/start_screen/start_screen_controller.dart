import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:momento_booth/views/base/printer_status_dialog_mixin.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/enter_pin_dialog.dart';
import 'package:momento_booth/views/components/dialogs/no_project_open_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view_model.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view.dart';

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
        dialog: NoProjectOpenDialog(onOpened: () => navigator.pop()), barrierDismissible: false,
      );
    }
  }

  // User interaction methods

  void onPressedContinue() {
    router.go(NavigationScreen.defaultRoute);
  }

  void onPressedGallery() {
    router.push(GalleryScreen.defaultRoute);
  }

  Future<void> onPressedOpenSettings() async {
    String? pincodeSetting = await getIt<SecretsRepository>().getSecret(settingsPincodeKey);
    if (pincodeSetting != null && pincodeSetting.isNotEmpty) {
      String? pincode = await showUserDialog(barrierDismissible: false, dialog: EnterPinDialog());
      if (pincode != pincodeSetting) return;
    }

    // ignore: use_build_context_synchronously
    await SettingsOverlay.openDialog(contextAccessor.buildContext, initialPage: SettingsPageKey.quickActions);
  }

}
