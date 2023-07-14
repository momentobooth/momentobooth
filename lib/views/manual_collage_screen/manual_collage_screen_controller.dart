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

  void refreshImageList() {
    clearSelection();
    viewModel.findImages();
  }

  void clearSelection() {
    for (var photo in selectedPhotos) {
      photo.isSelected= false;
    }
    PhotosManager.instance.reset(advance: false);
    viewModel.numSelected = 0;
    selectedPhotos.clear();
    loggy.debug("Cleared selection");
  }

  Future<void> tapPhoto(SelectableImage file) async {
    loggy.debug("Tapped image #${file.index} (${basename(file.file.path)}), selected: ${file.isSelected} at index ${file.selectedIndex}");
    
    final index = selectedPhotos.length;

    if (file.isSelected) {
      file.isSelected = false;
      PhotosManager.instance.photos.removeAt(file.selectedIndex);
      PhotosManager.instance.chosen.removeLast();
      selectedPhotos.remove(file);
      // Update indexes
      for (int i = 0; i < selectedPhotos.length; i++) {
        selectedPhotos[i].selectedIndex = i;
      }
      viewModel.numSelected = index-1;
    } else {
      if (index > 3) return;

      selectedPhotos.add(file);
      file
        ..isSelected = true
        ..selectedIndex = index;
      PhotosManager.instance.photos.add(await file.file.readAsBytes());
      PhotosManager.instance.chosen.add(index);
      viewModel.numSelected = index+1;
    }
  }

  String get outputFolder => SettingsManager.instance.settings.output.localFolder;

  Future<void> captureCollage() async {
    if (viewModel.numSelected < 1 || viewModel.isSaving) return;

    viewModel.isSaving = true;
    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManager.instance.settings.output.resolutionMultiplier;
    final format = SettingsManager.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManager.instance.settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');
  
    PhotosManager.instance.outputImage = exportImage;
    await PhotosManager.instance.writeOutput(advance: true);
    loggy.debug("Saved collage image to disk");
    viewModel.isSaving = false;
  }

}
