import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/share_screen/share_screen.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> with UiLoggy {

  // Initialization/Deinitialization

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  /// Global key for controlling the slider widget.
  GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  void togglePicture(int image) {
    if (PhotosManager.instance.chosen.contains(image)) {
      PhotosManager.instance.chosen.remove(image);
    } else {
      PhotosManager.instance.chosen.add(image);
    }
    captureCollage();
  }

  String get outputFolder => SettingsManager.instance.settings.output.localFolder;

  DateTime? latestCapture;

  void captureCollage() async {
    viewModel.readyToContinue = false;
    
    // It can happen that a previous capture takes longer than the latest one.
    // Therefore, keep track of which is the latest invocation.
    final thisCapture = DateTime.now();
    latestCapture = thisCapture;
    
    if (viewModel.numSelected < 1) return;

    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManager.instance.settings.output.resolutionMultiplier;
    final format = SettingsManager.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManager.instance.settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');

    if (latestCapture == thisCapture) {
      PhotosManager.instance.outputImage = exportImage;
      loggy.debug("Written collage image to output image memory");
      PhotosManager.instance.writeOutput();
      viewModel.readyToContinue = true;
    }
  }

  void onContinueTap() {
    if (!viewModel.readyToContinue) return;
    StatsManager.instance.addCreatedMultiCapturePhoto();
    router.go(ShareScreen.defaultRoute);
  }

}
