import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';

class NavigationScreenController extends ScreenControllerBase<NavigationScreenViewModel> {

  AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  // Initialization/Deinitialization

  NavigationScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  Future<void> onClickPhoto() async {
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

  void onClickGallery() {
    router.go(GalleryScreen.defaultRoute);
  }

}
