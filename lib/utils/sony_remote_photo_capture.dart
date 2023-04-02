import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'capture_method.dart';

class SonyRemotePhotoCapture extends CaptureMethod {
  final String directoryPath;

  SonyRemotePhotoCapture(this.directoryPath);

  @override
  void capture() {
    // AutoIt script line
    // https://ss64.com/nt/syntax-esc.html
    var autoItScript = "ControlClick('Remote', '', 1001)";

    // Execute the AutoIt script using the AutoIt executable
    Process.run('autoit3.exe', ['/AutoIt3ExecuteLine', autoItScript]);
  }

  @override
  Future<Uint8List> getPhoto() async {
    try {
      final file = await waitForFile(directoryPath, ".jpg");
      final img = await file.readAsBytes();
      print('File found: ${file.path}');
      return img;
    } on TimeoutException {
      throw 'File not found within 5 seconds';
    }
  }

  @override
  Future<Uint8List> captureAndGetPhoto() {
    capture();
    return getPhoto();
  }

  Future<File> waitForFile(String directoryPath, String fileExtension) async {
    print("Checking for new $fileExtension files");
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
