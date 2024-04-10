import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view.dart';
import 'package:path/path.dart' hide context;

part 'gallery_screen_view_model.g.dart';

class GalleryScreenViewModel = GalleryScreenViewModelBase with _$GalleryScreenViewModel;

abstract class GalleryScreenViewModelBase extends ScreenViewModelBase with Store {

  GalleryScreenViewModelBase({
    required super.contextAccessor,
  }) {
    findImages();
  }

  ScrollController myScrollController = ScrollController();
  
  final DateFormat formatter = DateFormat("MMM dd – HH:mm");

  Directory get outputDir => Directory(SettingsManager.instance.settings.output.localFolder);
  String get baseName => PhotosManager.instance.baseName;
  
  @readonly
  List<GalleryGroup>? _imageGroups;

  List<String>? imageNames;

  @observable
  SortBy sortBy = SortBy.time;

  void onSortByChanged(newSortBy) {
    sortBy = newSortBy;
    findImages();
  }

  void filterImages(List<String> matchingImagesStrings) {
    imageNames = matchingImagesStrings;
    findImages();
  }

  @action
  Future<void> findImages() async {
    final outputDirFiles = await outputDir.list().toList();
    Iterable<File> eligibleFiles = outputDirFiles.whereType<File>()
      .where((file) => basename(file.path).startsWith(baseName));

    // Find EXIF data
    List<GalleryImage> imagesWithExif = [];
    for (File file in eligibleFiles) {
      // Check if there is a filter
      if (imageNames != null && !imageNames!.contains(basename(file.path))) continue;
      imagesWithExif.add(GalleryImage(
        file: file,
        exifTags: await getMomentoBoothExifTagsFromFile(imageFilePath: file.path),
      ));
    }
    
    if (sortBy == SortBy.time){
      // Group images and sort within groups
      List<GalleryGroup> imageGroups = imagesWithExif
          .groupListsBy((image) => image.createdDate != null
              ? DateTime(
                  image.createdDate!.year,
                  image.createdDate!.month,
                  image.createdDate!.day,
                  image.createdDate!.hour,
                )
              : null)
          .entries
          .map((entry) => GalleryGroup(
              title: formatter.format(entry.key!),
              images: entry.value
                ..sort((a, b) => (b.createdDate ?? DateTime(1970)).compareTo(a.createdDate ?? DateTime(1970)))))
          .toList()
        ..sort((a, b) => (b.createdDayAndHour ?? DateTime(1970)).compareTo(a.createdDayAndHour ?? DateTime(1970)));

      _imageGroups = imageGroups;
    } else {
      // Group images and sort within groups
      List<GalleryGroup> imageGroups = imagesWithExif
          .groupListsBy((image) => 1)
          .entries
          .map((entry) => GalleryGroup(
              title: "${entry.key} person",
              images: entry.value
                ..sort((a, b) => (b.createdDate ?? DateTime(1970)).compareTo(a.createdDate ?? DateTime(1970)))))
          .toList();

      _imageGroups = imageGroups;
    }
  }

}
