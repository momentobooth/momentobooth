import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';
import 'package:path/path.dart' hide context;

class ManualCollageScreenController extends ScreenControllerBase<ManualCollageScreenViewModel> with UiLoggy {

  // Initialization/Deinitialization

  ManualCollageScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  /// Global key for controlling the slider widget.
  GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  final selectedPhotos = <SelectableImage>[];

  void clearSelection() {
    for (var photo in selectedPhotos) {
      photo.isSelected= false;
    }
    PhotosManagerBase.instance.reset(advance: false);
    viewModel.numSelected = 0;
    selectedPhotos.clear();
    loggy.debug("Cleared selection");
  }

  void tapPhoto(SelectableImage file) async {
    loggy.debug("Tapped image #${file.index} (${basename(file.file.path)}), selected: ${file.isSelected} at index ${file.selectedIndex}");
    
    final index = selectedPhotos.length;

    if (file.isSelected) {
      file.isSelected = false;
      PhotosManagerBase.instance.photos.removeAt(file.selectedIndex);
      PhotosManagerBase.instance.chosen.removeLast();
      selectedPhotos.remove(file);
      // Update indexes
      for (int i = 0; i < selectedPhotos.length; i++) {
        selectedPhotos[i].selectedIndex = i;
      }
      viewModel.numSelected = index-1;
    } else {
      if (index > 3) return;

      selectedPhotos.add(file);
      file.isSelected = true;
      file.selectedIndex = index;
      PhotosManagerBase.instance.photos.add(await file.file.readAsBytes());
      PhotosManagerBase.instance.chosen.add(index);
      viewModel.numSelected = index+1;
    }
    captureCollage();
  }

  String get outputFolder => SettingsManagerBase.instance.settings.output.localFolder;

  DateTime? latestCapture;

  late Completer captureComplete;

  void captureCollage() async {
    if (viewModel.numSelected < 1) return;

    captureComplete = Completer();
    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManagerBase.instance.settings.output.resolutionMultiplier;
    final format = SettingsManagerBase.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManagerBase.instance.settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');
  
    PhotosManagerBase.instance.outputImage = exportImage;
    loggy.debug("Written collage image to output image memory");
    captureComplete.complete();
  }

  void saveCollage() async {
    await captureComplete.future;
    PhotosManagerBase.instance.writeOutput(advance: true);
    loggy.debug("Saved collage image to disk");
  }

}
