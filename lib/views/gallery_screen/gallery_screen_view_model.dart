import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:path/path.dart' hide context;

part 'gallery_screen_view_model.g.dart';

class GalleryScreenViewModel = GalleryScreenViewModelBase with _$GalleryScreenViewModel;

abstract class GalleryScreenViewModelBase extends ScreenViewModelBase with Store {

  GalleryScreenViewModelBase({
    required super.contextAccessor,
  }) {
    findImages();
  }

  Directory get outputDir => Directory(SettingsManager.instance.settings.output.localFolder);
  String get baseName => PhotosManager.instance.baseName;
  
  @readonly
  Map<DateTime?, List<GalleryImage>>? _imageGroups;

  @action
  Future<void> findImages() async {
    final outputDirFiles = await outputDir.list().toList();
    Iterable<File> eligibleFiles = outputDirFiles.whereType<File>()
      .where((file) => basename(file.path).startsWith(baseName));

    // Find EXIF data
    List<GalleryImage> imagesWithExif = [];
    for (File file in eligibleFiles) {
      imagesWithExif.add(GalleryImage(
        file: file,
        exifTags: await rustLibraryApi.getMomentoBoothExifTagsFromFile(imageFilePath: file.path),
      ));
    }

    // Group images and sort within groups
    Map<DateTime?, List<GalleryImage>> imageGroups = imagesWithExif.groupListsBy((image) => image.createdDate != null ? DateTime(
      image.createdDate!.year,
      image.createdDate!.month,
      image.createdDate!.day,
      image.createdDate!.hour,
    ) : null);
    imageGroups.values.map((imageList) => imageList.sort((a, b) => (a.createdDate ?? DateTime(1970)).compareTo(b.createdDate ?? DateTime(1970))));

    _imageGroups = imageGroups;
  }

}
