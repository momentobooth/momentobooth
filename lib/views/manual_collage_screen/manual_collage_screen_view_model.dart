import 'dart:io';

import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

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

abstract class ManualCollageScreenViewModelBase extends ScreenViewModelBase with Store {

  ManualCollageScreenViewModelBase({
    required super.contextAccessor,
  }) {
    findImages();
  }

  @observable
  int numSelected = 0;

  double get collageAspectRatio => SettingsManagerBase.instance.settings.collageAspectRatio;
  double get collagePadding => SettingsManagerBase.instance.settings.collagePadding;

  int get rotation => [0, 1, 4].contains(numSelected) ? 1 : 0;

  final Duration opacityDuraction = Duration(milliseconds: 300);

  @observable
  String directoryString = SettingsManagerBase.instance.settings.hardware.captureLocation;

  Directory get outputDir => Directory(directoryString);
  
  @observable
  ObservableList<SelectableImage> fileList = ObservableList<SelectableImage>();

  @action
  Future<void> findImages() async {
    fileList.clear();
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => file.path.toLowerCase().endsWith('.jpg'));

    int i = 0;
    for (var file in matchingFiles) {
      fileList.add(SelectableImage(file: file, index: i++));
    }
  }

}
