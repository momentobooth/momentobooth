import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:momento_booth/exceptions/photo_capture_exception.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:momento_booth/utils/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Capture method that captures an image by automating the Sony Imaging Edge Desktop application (Windows only).
/// This solution exists because gPhoto2 and other possibly better solutions require driver overrides on Windows or
/// require bundling shared libraries which we do not support at the moment.
class SonyRemotePhotoCapture extends PhotoCaptureMethod {

  static const String autoItScriptFileName = "sony_remote_capture_photo.au3";

  final String directoryPath;

  SonyRemotePhotoCapture(this.directoryPath);

  // Testing with camera gave ~165 ms with manual focus, ~220 with good autofocus
  // and up to 500 ms in bad light. Differs per lens as well.
  // Short button presses will not trigger the capture when focussing is not complete.
  @override
  Duration get captureDelay => Duration(milliseconds: getIt<SettingsManager>().settings.hardware.captureDelaySony);

  Future<void> _capture() async {
    logDebug("Sending capture command to Sony Remote");
    // AutoIt script line
    // https://ss64.com/nt/syntax-esc.html
    var autoItScriptPath = await _ensureAutoItScriptIsExtracted();

    // Execute the AutoIt script using the AutoIt executable
    unawaited(Process.run('autoit3.exe', ['/AutoIt3ExecuteScript', autoItScriptPath]));
  }

  Future<PhotoCapture> _getPhoto() async {
    try {
      final file = await waitForFile(directoryPath, ".jpg");
      final img = await file.readAsBytes();
      logDebug('Photo found: ${file.path}');
      return PhotoCapture(
        data: img,
        filename: path.basename(file.path),
      );
    } on TimeoutException {
      throw PhotoCaptureException.fromImplementationRuntimeType('File not found within 5 seconds', this);
    }
  }

  @override
  Future<PhotoCapture> captureAndGetPhoto() {
    _capture();
    return _getPhoto();
  }

  Future<File> waitForFile(String directoryPath, String fileExtension) async {
    logDebug("Checking for new $fileExtension files");

    final stopTime = DateTime.now().add(const Duration(seconds: 5));
    final dir = Directory(directoryPath);
    final fileListBefore = await dir.list().toList();
    final matchingFilesBefore = fileListBefore.whereType<File>().where(
          (file) => file.path.toLowerCase().endsWith(fileExtension),
        );

    while (DateTime.now().isBefore(stopTime)) {
      final files = await dir.list().toList();
      final matchingFiles = files.whereType<File>().where((file) => file.path.toLowerCase().endsWith(fileExtension));
      if (matchingFiles.length > matchingFilesBefore.length) return matchingFiles.last;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    throw TimeoutException('Timed out while waiting for file to exist');
  }

  Future<String> _ensureAutoItScriptIsExtracted() async {
    final Directory docDir = await getApplicationSupportDirectory();
    final String localPath = '${docDir.path}\\$autoItScriptFileName';
    if (!File(localPath).existsSync()) {
      final imageBytes = await rootBundle.load('assets/scripts/$autoItScriptFileName');
      await writeBytesToFileLocked(localPath, imageBytes.buffer.asUint8List());
      logInfo("Written Sony Remote AutoIt capture script to: $localPath");
    }
    return localPath;
  }

  @override
  Future<void> clearPreviousEvents() async {}

}
