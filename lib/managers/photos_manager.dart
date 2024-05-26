import 'dart:io';
import 'dart:typed_data';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:path/path.dart' show basename, join; // Without show mobx complains
import 'package:path_provider/path_provider.dart';

part 'photos_manager.g.dart';

class PhotosManager extends _PhotosManagerBase with _$PhotosManager {

  static final PhotosManager instance = PhotosManager._internal();

  PhotosManager._internal();

}

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
abstract class _PhotosManagerBase with Store {

  @observable
  ObservableList<PhotoCapture> photos = ObservableList<PhotoCapture>();

  @observable
  Uint8List? outputImage;

  @observable
  ObservableList<int> chosen = ObservableList<int>();

  @observable
  CaptureMode captureMode = CaptureMode.single;

  @computed
  bool get showLiveViewBackground => photos.isEmpty && captureMode == CaptureMode.single;

  Directory get outputDir => Directory(getIt<SettingsManager>().settings.output.localFolder);
  int photoNumber = 0;
  bool photoNumberChecked = false;

  final String baseName = "MomentoBooth-image";

  Iterable<PhotoCapture> get chosenPhotos => chosen.map((choice) => photos[choice]);

  @action
  void reset({bool advance = true}) {
    photos.clear();
    chosen.clear();
    captureMode = CaptureMode.single;
    if (advance) photoNumber++;
  }

  @action
  Future<File?> writeOutput({bool advance = false}) async {
    if (outputImage == null) return null;
    if (!photoNumberChecked) {
      photoNumber = await findLastImageNumber() + 1;
      photoNumberChecked = true;
    }
    final fileExtension = getIt<SettingsManager>().settings.output.exportFormat.name.toLowerCase();
    final filePath = join(outputDir.path, '$baseName-${photoNumber.toString().padLeft(4, '0')}.$fileExtension');
    if (advance) photoNumber++;
    return await writeBytesToFileLocked(filePath, outputImage!);
  }

  @action
  Future<int> findLastImageNumber() async {
    if (!outputDir.existsSync()) outputDir.createSync();
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => basename(file.path).startsWith(baseName));

    if (matchingFiles.isEmpty) return 0;

    final lastImg = matchingFiles.last;
    final pattern = RegExp(r'\d+');
    final match = pattern.firstMatch(basename(lastImg.path));
    return match != null ? int.parse(match.group(0) ?? "0") : 0;
  }

  Future<File> getOutputImageAsTempFile() async {
    final Directory tempDir = await getTemporaryDirectory();
    final fileExtension = getIt<SettingsManager>().settings.output.exportFormat.name.toLowerCase();
    final filePath = join(tempDir.path, 'image.$fileExtension');
    return await writeBytesToFileLocked(filePath, outputImage!);
  }

  Future<Uint8List> getOutputPDF(PrintSize printSize) => getImagePdfWithPageSize(outputImage!, printSize);

}
