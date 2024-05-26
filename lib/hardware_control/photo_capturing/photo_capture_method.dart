import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:momento_booth/main.dart';
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

        await Directory(getIt<SettingsManager>().settings.hardware.captureStorageLocation).create(recursive: true);

        String filePath = path.join(getIt<SettingsManager>().settings.hardware.captureStorageLocation, fileName);
        await writeBytesToFileLocked(filePath, fileData);
        logDebug("Stored incoming photo to disk: $filePath");
      } catch (exception, stacktrace) {
        logError("Could not save photo to disk", exception, stacktrace);
      }
    }
  }

}
