import 'package:flutter/widgets.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/share_screen/share_screen.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> {

  // Initialization/Deinitialization

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  /// Global key for controlling the slider widget.
  GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  void togglePicture(int image) {
    if (PhotosManagerBase.instance.chosen.contains(image)) {
      PhotosManagerBase.instance.chosen.remove(image);
    } else {
      PhotosManagerBase.instance.chosen.add(image);
    }
    captureCollage();
  }

  String get outputFolder => SettingsManagerBase.instance.settings.output.localFolder;

  DateTime? latestCapture;

  void captureCollage() async {
    viewModel.readyToContinue = false;
    
    // It can happen that a previous capture takes longer than the latest one.
    // Therefore, keep track of which is the latest invocation.
    final thisCapture = DateTime.now();
    latestCapture = thisCapture;
    
    if (viewModel.numSelected < 1) return;

    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManagerBase.instance.settings.output.resolutionMultiplier;
    final format = SettingsManagerBase.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManagerBase.instance.settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    print('captureCollage() executed in ${stopwatch.elapsed}');

    if (latestCapture == thisCapture) {
      PhotosManagerBase.instance.outputImage = exportImage;
      print("Written collage image to output image memory");
      PhotosManagerBase.instance.writeOutput();
      viewModel.readyToContinue = true;
    }
  }

  void onContinueTap() {
    if (!viewModel.readyToContinue) return;
    router.go(ShareScreen.defaultRoute);
  }

}
