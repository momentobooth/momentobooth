import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';
import 'package:path/path.dart' as path;

class ManualCollageScreenController extends ScreenControllerBase<ManualCollageScreenViewModel> {

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
    getIt<PhotosManager>().reset(advance: false);
    viewModel.numSelected = 0;
    selectedPhotos.clear();
    logDebug("Cleared selection");
  }

  Future<void> tapPhoto(SelectableImage file) async {
    logDebug("Tapped image #${file.index} (${path.basename(file.file.path)}), selected: ${file.isSelected} at index ${file.selectedIndex}, ctrl: ${viewModel.isControlPressed}, shift: ${viewModel.isShiftPressed}");

    if (viewModel.isShiftPressed) {
      final lastSelected = selectedPhotos.last.index;
      final tapped = file.index;
      final direction = tapped > lastSelected;
      if (direction) {
        for (int i = lastSelected+1; i <= tapped; i++) {
          await selectPhoto(viewModel.fileList[i]);
        }
      } else {
        for (int i = lastSelected-1; i >= tapped; i--) {
          await selectPhoto(viewModel.fileList[i]);
        }
      }
    } else if (viewModel.isControlPressed) {
      for (int i = 0; i < 4; i++) {
        await selectPhoto(viewModel.fileList[file.index+i]);
      }
    } else {
      await selectPhoto(file);
    }
  }

  Future<void> selectPhoto(SelectableImage file) async {
    final index = selectedPhotos.length;

    if (file.isSelected) {
      file.isSelected = false;
      getIt<PhotosManager>().photos.removeAt(file.selectedIndex);
      getIt<PhotosManager>().chosen.removeLast();
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
      getIt<PhotosManager>().photos.add(PhotoCapture(
        data: await file.file.readAsBytes(),
        filename: path.basename(file.file.path),
      ));
      getIt<PhotosManager>().chosen.add(index);
      viewModel.numSelected = index+1;
    }
  }

  String get outputFolder => getIt<SettingsManager>().settings.output.localFolder;

  Future<void> captureCollage() async {
    if (viewModel.numSelected < 1 || viewModel.isSaving) return;

    viewModel.isSaving = true;
    final stopwatch = Stopwatch()..start();
    final pixelRatio = getIt<SettingsManager>().settings.output.resolutionMultiplier;
    final format = getIt<SettingsManager>().settings.output.exportFormat;
    final jpgQuality = getIt<SettingsManager>().settings.output.jpgQuality;
    final exportImage = await collageKey.currentState!.getCollageImage(
      createdByMode: CreatedByMode.manual,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );
    logDebug('captureCollage took ${stopwatch.elapsed}');

    getIt<PhotosManager>().outputImage = exportImage;
    File? file = await getIt<PhotosManager>().writeOutput(advance: true);
    logDebug("Saved collage image to disk");

    if (viewModel.printOnSave) {
      String jobName = file != null ? path.basenameWithoutExtension(file.path) : "MomentoBooth Collage";
      await getIt<PrintingManager>().printPdf(jobName, await getImagePDF(exportImage!));
    }
    if (viewModel.clearOnSave) {
      clearSelection();
    }
    viewModel.isSaving = false;
  }

}
