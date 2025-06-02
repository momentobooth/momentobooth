import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view.dart';
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

  Directory get outputDir => getIt<ProjectManager>().getOutputDir();
  String get baseName => getIt<PhotosManager>().baseName;

  bool get isFaceRecognitionEnabled => getIt<SettingsManager>().settings.faceRecognition.enable;

  @readonly
  List<GalleryGroup>? _imageGroups;

  @observable
  List<String>? imageNames;
  List<int> ranges = [1, 2, 3, 4, 6, 10, 15];

  @observable
  SortBy sortBy = SortBy.time;

  void onSortByChanged(SortBy newSortBy) {
    sortBy = newSortBy;
    findImages();
  }

  void filterImages(List<String> matchingImagesStrings) {
    imageNames = matchingImagesStrings;
    findImages();
  }

  String getBucket(int? num) {
    if (num == null || num == 0) return "Unknown";
    if (num == 1) return "1 person";

    for (int i = 0; i < ranges.length-1; i++) {
      bool isRange = ranges[i+1] - ranges[i] > 1;
      if (num >= ranges[i] && num < ranges[i+1]) return isRange ? "${ranges[i]}-${ranges[i+1]-1} people" : "${ranges[i]} people";
    }

    return "> ${ranges.last} people";
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

    if (sortBy == SortBy.time) {
      // Group images and sort within groups
      List<GalleryGroup> imageGroups = imagesWithExif
          .groupListsBy((image) {
              var date = image.createdDate;
              return DateTime(
                date.year,
                date.month,
                date.day,
                date.hour,
              );
          })
          .entries
          .map((entry) => GalleryGroup(
              title: formatter.format(entry.key),
              createdDayAndHour: entry.key,
              images: entry.value
                ..sort((a, b) => b.createdDate.compareTo(a.createdDate))))
          .toList()
        ..sort((a, b) => (b.createdDayAndHour!).compareTo(a.createdDayAndHour!));

      _imageGroups = imageGroups;
    } else {
      // Group images and sort within groups
      List<GalleryGroup> imageGroups = imagesWithExif
          .groupListsBy((image) => getBucket(image.makerNoteData?.peopleCount))
          .entries
          .map((entry) => GalleryGroup(
              title: entry.key,
              images: entry.value
                ..sort((a, b) => (a.makerNoteData?.peopleCount ?? 0).compareTo(b.makerNoteData?.peopleCount ?? 0))))
          .toList()
        ..sort((a, b) => (a.images.first.makerNoteData?.peopleCount ?? 0).compareTo(b.images.first.makerNoteData?.peopleCount ?? 0));

      _imageGroups = imageGroups;
    }
  }

}
