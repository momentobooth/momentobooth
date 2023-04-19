import 'dart:io';
import 'dart:typed_data';

import 'package:momento_booth/managers/settings_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' show basename, join; // Without show mobx complains

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

enum CaptureMode {

  single(0, "Single"),
  collage(1, "Collage");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const CaptureMode(this.value, this.name);

}

/// Class containing global state for photos in the app
abstract class PhotosManagerBase with Store {

  static final PhotosManagerBase instance = PhotosManager._internal();

  @observable
  ObservableList<Uint8List> photos = ObservableList<Uint8List>();

  @observable
  Uint8List? outputImage;

  @observable
  ObservableList<int> chosen = ObservableList<int>();

  @observable
  CaptureMode captureMode = CaptureMode.single;

  @computed
  bool get showLiveViewBackground => photos.isEmpty && captureMode == CaptureMode.single;

  Directory get outputDir => Directory(SettingsManagerBase.instance.settings.output.localFolder);
  int photoNumber = 0;
  bool photoNumberChecked = false;
  String baseName = "MomentoBooth-image";
 
  Iterable<Uint8List> get chosenPhotos => chosen.map((choice) => photos[choice]);

  PhotosManagerBase._internal();

  @action
  void reset({bool advance = true}) {
    photos.clear();
    chosen.clear();
    captureMode = CaptureMode.single;
    if (advance) { photoNumber++; }
  }

  @action
  Future<File?> writeOutput() async {
    if (instance.outputImage == null) return null;
    if (!photoNumberChecked) {
      photoNumber = await findLastImageNumber()+1;
      photoNumberChecked = true;
    }
    final extension = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();
    final filePath = join(outputDir.path, '$baseName-${photoNumber.toString().padLeft(4, '0')}.$extension');
    File file = await File(filePath).create();
    return await file.writeAsBytes(instance.outputImage!);
  }
  
  @action
  Future<int> findLastImageNumber() async {
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => basename(file.path).startsWith(baseName));
    
    if (matchingFiles.isEmpty) { return 0; }

    final lastImg = matchingFiles.last;
    final pattern = RegExp(r'\d+');
    final match = pattern.firstMatch(basename(lastImg.path));
    if (match != null) {
      return int.parse(match.group(0) ?? "0");
    }
    return 0;
  }

}
