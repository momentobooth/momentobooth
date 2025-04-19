
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> {

  // Initialization/Deinitialization

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  /// Global key for controlling the slider widget.
  GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  void togglePicture(int image) {
    if (getIt<PhotosManager>().chosen.contains(image)) {
      getIt<PhotosManager>().chosen.remove(image);
    } else {
      getIt<PhotosManager>().chosen.add(image);
    }
  }

  Future<void> onContinueTap() async {
    if (viewModel.isGeneratingImage || getIt<PhotosManager>().chosen.isEmpty) return;
    viewModel.isGeneratingImage = true;

    final stopwatch = Stopwatch()..start();
    final pixelRatio = getIt<SettingsManager>().settings.output.resolutionMultiplier;
    final format = getIt<SettingsManager>().settings.output.exportFormat;
    final jpgQuality = getIt<SettingsManager>().settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(
      createdByMode: CreatedByMode.multi,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );
    logDebug('captureCollage took ${stopwatch.elapsed}');

    getIt<PhotosManager>().outputImage = exportImage;
    logDebug("Written collage image to output image memory");
    await getIt<PhotosManager>().writeOutput();

    viewModel.isGeneratingImage = false;

    // FIXME: There is a possibility that a collage will not get registered in the stats
    // because a user leaves it and after timeout navigation to the homescreen occurs.

    getIt<StatsManager>().addCreatedMultiCapturePhoto();
    router.go(ShareScreen.defaultRoute);
  }

}
