import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'manual_collage_screen_view_model.g.dart';

class ManualCollageScreenViewModel = ManualCollageScreenViewModelBase with _$ManualCollageScreenViewModel;

class SelectableImage {
  late final File file;
  bool isSelected = false;
  int selectedIndex = 0;
  late final int index;

  SelectableImage({
    required this.file,
    required this.index,
  });
}

abstract class ManualCollageScreenViewModelBase extends ScreenViewModelBase with Store, UiLoggy {

  ManualCollageScreenViewModelBase({
    required super.contextAccessor,
  }) {
    findImages();
  }

  @observable
  int numSelected = 0;

  double get collageAspectRatio => SettingsManager.instance.settings.collageAspectRatio;
  double get collagePadding => SettingsManager.instance.settings.collagePadding;

  int get rotation => [0, 1, 4].contains(numSelected) ? 1 : 0;

  final Duration opacityDuraction = const Duration(milliseconds: 300);

  @observable
  String directoryString = SettingsManager.instance.settings.hardware.captureLocation;

  Directory get outputDir => Directory(directoryString);

  @observable
  bool isSaving = false;
  
  @observable
  ObservableList<SelectableImage> fileList = ObservableList<SelectableImage>();

  @action
  Future<void> findImages() async {
    loggy.debug("Searching for images");
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => file.path.toLowerCase().endsWith('.jpg'));

    fileList.clear();
    int i = 0;
    for (var file in matchingFiles) {
      fileList.add(SelectableImage(file: file, index: i++));
    }
    loggy.debug("Found ${matchingFiles.length} images");
  }

}
