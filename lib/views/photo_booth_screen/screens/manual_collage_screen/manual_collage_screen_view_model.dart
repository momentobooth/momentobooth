import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/utils/logging.dart';
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

abstract class ManualCollageScreenViewModelBase extends ScreenViewModelBase with Store {

  ManualCollageScreenViewModelBase({
    required super.contextAccessor,
  }) {
    findImages();
    focusNode.requestFocus();
  }

  @observable
  int numSelected = 0;

  double get collageAspectRatio => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  int get rotation => [0, 1, 4].contains(numSelected) ? 1 : 0;

  final Duration opacityDuraction = const Duration(milliseconds: 300);

  final focusNode = FocusNode();
  bool isShiftPressed = false;
  bool isControlPressed = false;

  @observable
  bool printOnSave = false;
  @observable
  bool clearOnSave = false;

  @observable
  String directoryString = getIt<SettingsManager>().settings.hardware.captureLocation;

  Directory get outputDir => Directory(directoryString);

  @observable
  bool isSaving = false;

  @observable
  ObservableList<SelectableImage> fileList = ObservableList<SelectableImage>();

  @action
  Future<void> findImages() async {
    logDebug("Searching for images");
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => file.path.toLowerCase().endsWith('.jpg'));

    fileList.clear();
    int i = 0;
    for (var file in matchingFiles) {
      fileList.add(SelectableImage(file: file, index: i++));
    }
    logDebug("Found ${matchingFiles.length} images");
  }

}
