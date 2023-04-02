import 'dart:io';
import 'dart:async';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';

class CaptureScreenController extends ScreenControllerBase<CaptureScreenViewModel> {

  // Initialization/Deinitialization

  CaptureScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  Future<void> captureAndGetPhoto() async {
    print("Start capture and get function");
    capturePhoto();
    print("Captured photo using AutoIT");
    
    try {
      final file = await waitForFile(r"C:\Users\caspe\Pictures", ".jpg");
      print('File found: ${file.path}');
    } on TimeoutException {
      print('File not found within 5 seconds');
    }
  }

  void capturePhoto() {
    // AutoIt script line
    var autoItScript = 'ControlClick(\'Remosdte\', \'\', 1001)';

    // Execute the AutoIt script using the AutoIt executable
    Process.run('autoit3.exe', ['/AutoIt3ExecuteLine', autoItScript]);
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
