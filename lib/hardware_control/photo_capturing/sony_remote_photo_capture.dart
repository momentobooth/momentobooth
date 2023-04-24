import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';

/// Capture method that captures an image by automating the Sony Imaging Edge Desktop application (Windows only).
/// This solution exists because gPhoto2 and other possibly better solutions require driver overrides on Windows or
/// require bundling shared libraries which we do not support at the moment.
class SonyRemotePhotoCapture extends PhotoCaptureMethod with UiLoggy {

  final String directoryPath;

  SonyRemotePhotoCapture(this.directoryPath);

  // Testing with camera gave ~165 ms with manual focus, ~220 with good autofocus
  // and up to 500 ms in bad light. This should be avoided anyway because the (short)
  // button press will not trigger the camera then. 
  @override
  Duration get captureDelay => Duration(milliseconds: 200);

  void _capture() {
    loggy.debug("Sending capture command to Sony Remote");
    // AutoIt script line
    // https://ss64.com/nt/syntax-esc.html
    var autoItScript = "ControlClick('Remote', '', 1001)";

    // Execute the AutoIt script using the AutoIt executable
    Process.run('autoit3.exe', ['/AutoIt3ExecuteLine', autoItScript]);
  }

  Future<Uint8List> _getPhoto() async {
    try {
      final file = await waitForFile(directoryPath, ".jpg");
      final img = await file.readAsBytes();
      loggy.debug('Photo found: ${file.path}');
      return img;
    } on TimeoutException {
      throw 'File not found within 5 seconds';
    }
  }

  @override
  Future<Uint8List> captureAndGetPhoto() {
    _capture();
    return _getPhoto();
  }

  Future<File> waitForFile(String directoryPath, String fileExtension) async {
    loggy.debug("Checking for new $fileExtension files");
    
    final stopTime = DateTime.now().add(Duration(seconds: 5));
    final dir = Directory(directoryPath);
    final fileListBefore = await dir.list().toList();
    final matchingFilesBefore = fileListBefore.whereType<File>().where((file) => file.path.toLowerCase().endsWith(fileExtension));
    
    while (DateTime.now().isBefore(stopTime)) {
      final files = await dir.list().toList();
      final matchingFiles = files.whereType<File>().where((file) => file.path.toLowerCase().endsWith(fileExtension));
      if (matchingFiles.length > matchingFilesBefore.length) {
        return matchingFiles.last;
      }
      await Future.delayed(Duration(milliseconds: 250));
    }
    throw TimeoutException('Timed out while waiting for file to exist');
  }

}
