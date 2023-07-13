import 'dart:io';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
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
  
  @observable
  ObservableList<File> fileList = ObservableList<File>();

  @action
  Future<void> findImages() async {
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => basename(file.path).startsWith(baseName));
    for (var file in matchingFiles) {
      fileList.add(file);
    }
  }

}
