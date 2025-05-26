import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/language_choice_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/recording_countdown_screen/recording_countdown_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/single_capture_screen/single_capture_screen.dart';

class NavigationScreenController extends ScreenControllerBase<NavigationScreenViewModel> {

  AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  // Initialization/Deinitialization

  NavigationScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  // User interaction methods

  Future<void> onClickSinglePhoto() async {
    router.go(SingleCaptureScreen.defaultRoute);
  }

  Future<void> onClickCollage() async {
    router.go(MultiCaptureScreen.defaultRoute);
  }

  Future<void> onClickRecord() async {
    getIt<PhotosManager>().captureMode = CaptureMode.recording;
    router.go(RecordingCountdownScreen.defaultRoute);
  }

  Future<void> onClickPhoto() async {
    final singleCapture = viewModel.enableSingleCapture;
    final collageCapture = viewModel.enableCollageCapture;
    if (singleCapture) {
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
    router.push(GalleryScreen.defaultRoute);
  }

  Future<void> onClickLanguage() async {
    await showUserDialog(
      dialog: LanguageChoiceDialog(onChosen: (language) {
        navigator.pop();
        getIt<WindowManager>().setLanguage(language);
      },), barrierDismissible: true,
    );
  }

}
