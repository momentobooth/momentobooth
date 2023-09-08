import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/exceptions/photo_capture_exception.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Capture method that captures an image by automating the Sony Imaging Edge Desktop application (Windows only).
/// This solution exists because gPhoto2 and other possibly better solutions require driver overrides on Windows or
/// require bundling shared libraries which we do not support at the moment.
class SonyRemotePhotoCapture extends PhotoCaptureMethod with UiLoggy {

  static const String autoItScriptFileName = "sony_remote_capture_photo.au3";

  final String directoryPath;

  SonyRemotePhotoCapture(this.directoryPath);

  // Testing with camera gave ~165 ms with manual focus, ~220 with good autofocus
  // and up to 500 ms in bad light. Differs per lens as well.
  // Short button presses will not trigger the capture when focussing is not complete.
  @override
  Duration get captureDelay => Duration(milliseconds: SettingsManager.instance.settings.hardware.captureDelaySony);

  Future<void> _capture() async {
    loggy.debug("Sending capture command to Sony Remote");
    // AutoIt script line
    // https://ss64.com/nt/syntax-esc.html
    var autoItScriptPath = await _ensureAutoItScriptIsExtracted();

    // Execute the AutoIt script using the AutoIt executable
    unawaited(Process.run('autoit3.exe', ['/AutoIt3ExecuteScript', autoItScriptPath]));
  }

  Future<Uint8List> _getPhoto() async {
    try {
      final file = await waitForFile(directoryPath, ".jpg");
      final img = await file.readAsBytes();
      loggy.debug('Photo found: ${file.path}');
      return img;
    } on TimeoutException {
      throw PhotoCaptureException.fromImplementationRuntimeType('File not found within 5 seconds', this);
    }
  }

  @override
  Future<Uint8List> captureAndGetPhoto() {
    _capture();
    return _getPhoto();
  }

  Future<File> waitForFile(String directoryPath, String fileExtension) async {
    loggy.debug("Checking for new $fileExtension files");

    final stopTime = DateTime.now().add(const Duration(seconds: 5));
    final dir = Directory(directoryPath);
    final fileListBefore = await dir.list().toList();
    final matchingFilesBefore =
        fileListBefore.whereType<File>().where((file) => file.path.toLowerCase().endsWith(fileExtension));

    while (DateTime.now().isBefore(stopTime)) {
      final files = await dir.list().toList();
      final matchingFiles = files.whereType<File>().where((file) => file.path.toLowerCase().endsWith(fileExtension));
      if (matchingFiles.length > matchingFilesBefore.length) {
        return matchingFiles.last;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    throw TimeoutException('Timed out while waiting for file to exist');
  }

  Future<String> _ensureAutoItScriptIsExtracted() async {
    final Directory docDir = await getApplicationSupportDirectory();
    final String localPath = '${docDir.path}\\$autoItScriptFileName';
    File file = File(localPath);
    if (!file.existsSync()) {
      final imageBytes = await rootBundle.load('assets/scripts/$autoItScriptFileName');
      final buffer = imageBytes.buffer;
      await file.writeAsBytes(buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));
      loggy.info("Written Sony Remote AutoIt capture script to: $localPath");
    }
    return localPath;
  }

  @override
  Future<void> clearPreviousEvents() async {}

}
