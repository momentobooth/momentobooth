import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';

part 'collage_maker_screen_view_model.g.dart';

class CollageMakerScreenViewModel = CollageMakerScreenViewModelBase with _$CollageMakerScreenViewModel;

abstract class CollageMakerScreenViewModelBase extends ScreenViewModelBase with Store {

  CollageMakerScreenViewModelBase({
    required super.contextAccessor,
  });

  int get numSelected => getIt<PhotosManager>().chosen.length;

  double get collageAspectRatio => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  int get rotation => [0, 1, 4].contains(numSelected) ? 1 : 0;

  @observable
  bool isGeneratingImage = false;

  final Duration opacityDuration = const Duration(milliseconds: 300);

 Future<void> generateCollage({required GlobalKey<PhotoCollageState> collageKey}) async {
    if (isGeneratingImage) return;
    isGeneratingImage = true;

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

    isGeneratingImage = false;
    getIt<StatsManager>().addCreatedMultiCapturePhoto();
  }

}
