import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_rust_bridge_example/managers/native_library_initialization_manager.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_api.generated.dart';
import 'package:flutter_rust_bridge_example/utils/image_processing.dart';

const _base = 'flutter_rust_bridge_example';
final _path = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';
final _dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(_path);

final rustLibraryApi = FlutterRustBridgeExampleImpl(_dylib);

void init() {
  // Initialize log
  Stream<LogEvent> logStream = rustLibraryApi.initializeLog();
  logStream.listen(processLogEvent);

  // Initialize hardware
  Stream<HardwareInitializationFinishedEvent> hardwareInitResultStream = rustLibraryApi.initializeHardware();
  hardwareInitResultStream.listen(processHardwareInitEvent);
}

void processLogEvent(LogEvent event) {
  print("Native Lib: ${event.message}");
}

void processHardwareInitEvent(HardwareInitializationFinishedEvent event) async {
  switch (event.step) {
    
    case HardwareInitializationStep.Nokhwa:
      HardwareStateManagerBase.instance.nokhwaIsInitialized = event.hasSucceeded;
      HardwareStateManagerBase.instance.nokhwaInitializationMessage = event.message;

      var cameras = await rustLibraryApi.nokhwaGetCameras();

      NokhwaCameraInfo camera = NokhwaCameraInfo(id: 1, friendlyName: "Microsoft® LifeCam HD-5000");
      var openCameraResult = await rustLibraryApi.nokhwaOpenCamera(cameraInfo: camera);
      var frameStream = rustLibraryApi.setCameraCallback(cameraPtr: openCameraResult.cameraPtr);
      var lastFrame = DateTime.now();
      frameStream.listen((event) async {
        AppImage img = AppImage.fromRawRgbaData(event, openCameraResult.width, openCameraResult.height);
        img.cropToAspectRatio(3/2);
        PhotosManagerBase.instance.currentWebcamImage = await img.toRawDartImage();
        var thisFrame = DateTime.now();
        print("${1E6/thisFrame.difference(lastFrame).inMicroseconds} FPS - $thisFrame");
        lastFrame = thisFrame;
      }).onError((error) {
        print(error);
      });
      print("Wait 60s");
      await Future.delayed(Duration(seconds: 60));
      print("Await close");
      await rustLibraryApi.nokhwaCloseCamera(cameraPtr: openCameraResult.cameraPtr);
      print("Closed!");
      break;

  }
}
