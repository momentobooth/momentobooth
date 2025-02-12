import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' as path;

abstract class PhotoCaptureMethod with Logger {

  Duration get captureDelay;

  Future<void> clearPreviousEvents();

  Future<PhotoCapture> captureAndGetPhoto();

  Future<void> storePhotoSafe(String filename, Uint8List fileData) async {
    if (getIt<SettingsManager>().settings.hardware.saveCapturesToDisk) {
      try {
        DateFormat formatter = DateFormat('yyyyMMdd_HHmmss');
        String currentDateTime = formatter.format(DateTime.now());
        String fileName = "${currentDateTime}_$filename";

        // FIXME can I conclude that this is not necessary anymore as the folder gets created when a project is opened, or must we assume that the folder can be deleted in the mean time?
        await getIt<ProjectManager>().getInputDir().create(recursive: true);

        String filePath = path.join(getIt<ProjectManager>().getInputDir().path, fileName);
        await writeBytesToFileLocked(filePath, fileData);
        logDebug("Stored incoming photo to disk: $filePath");
      } catch (exception, stacktrace) {
        logError("Could not save photo to disk", exception, stacktrace);
      }
    }
  }

}
