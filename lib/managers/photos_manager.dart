import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/capture_state.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/logging.dart';
import 'package:path/path.dart' show basename, join; // Without show mobx complains
import 'package:path_provider/path_provider.dart';

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

/// Class containing global state for photos in the app
abstract class PhotosManagerBase with Store {

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

  Directory get outputDir => getIt<ProjectManager>().getOutputDir();
  int photoNumber = 0;
  bool photoNumberChecked = false;

  final String baseName = "MomentoBooth-image";

  Iterable<PhotoCapture> get chosenPhotos => chosen.map((choice) => photos[choice]);

  File? _lastPhotoFile;
  File? get lastPhotoFile => _lastPhotoFile;

  @action
  void reset({bool advance = true}) {
    photos.clear();
    chosen.clear();
    captureMode = CaptureMode.single;
    if (advance) {
      photoNumber++;
      _lastPhotoFile = null;
    }
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
    final f = await writeBytesToFileLocked(filePath, outputImage!);
    _lastPhotoFile = f;
    return f;
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

  PhotoCaptureMethod get capturer => switch (getIt<SettingsManager>().settings.hardware.captureMethod) {
    CaptureMethod.liveViewSource => LiveViewStreamSnapshotCapturer(),
    CaptureMethod.sonyImagingEdgeDesktop => SonyRemotePhotoCapture(getIt<SettingsManager>().settings.hardware.captureLocation),
    CaptureMethod.gPhoto2 => getIt<LiveViewManager>().gPhoto2Camera!,
  };

  Future<PhotoCapture> directPhotoCapture() async {
    final capturer = this.capturer;
    await capturer.clearPreviousEvents();
    await captureAndGetPhoto(capturer, () => {});
    return photos.last;
  }

  void initiateDelayedPhotoCapture(VoidCallback onCaptureFinished, {int? captureDelayOverride}) {
    final capturer = this.capturer
    ..clearPreviousEvents();

    int counterStart = captureDelayOverride ?? getIt<SettingsManager>().settings.captureDelaySeconds;
    int autoFocusMsBeforeCapture = getIt<SettingsManager>().settings.hardware.gPhoto2AutoFocusMsBeforeCapture;
    Duration photoDelay = Duration(seconds: counterStart) - capturer.captureDelay + flashStartDuration;
    Duration autoFocusDelay = photoDelay - Duration(milliseconds: autoFocusMsBeforeCapture);

    if (autoFocusMsBeforeCapture > 0 && autoFocusDelay > Duration.zero && capturer is GPhoto2Camera) {
      Future.delayed(autoFocusDelay).then((_) => capturer.autoFocus());
    }

    Future.delayed(photoDelay).then((_) => captureAndGetPhoto(capturer, onCaptureFinished));
    getIt<MqttManager>().publishCaptureState(CaptureState.countdown);
  }

  Future<void> captureAndGetPhoto(PhotoCaptureMethod capturer, VoidCallback onCaptureFinished) async {
    getIt<MqttManager>().publishCaptureState(CaptureState.capturing);

    try {
      final image = await capturer.captureAndGetPhoto();
      getIt<StatsManager>().addCapturedPhoto();
      photos.add(image);
    } catch (e) {
      logWarning(e.toString());
      final ByteData data = await rootBundle.load('assets/bitmap/capture-error.png');
      photos.add(PhotoCapture(
        data: data.buffer.asUint8List(),
        filename: "capture-error.png",
      ));
    } finally {
      onCaptureFinished();
      getIt<MqttManager>().publishCaptureState(CaptureState.idle);
    }
  }

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
