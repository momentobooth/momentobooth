import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_rust_bridge_example/managers/native_library_initialization_manager.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/rust_bridge/library_api.generated.dart';

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

      var x = await rustLibraryApi.nokhwaGetCameras();

      NokhwaCameraInfo camera = NokhwaCameraInfo(id: 1, friendlyName: "Microsoft® LifeCam HD-5000");
      var openCameraResult = await rustLibraryApi.nokhwaOpenCamera(cameraInfo: camera);
      var testing = rustLibraryApi.setCameraCallback(cameraPtr: openCameraResult.cameraPtr);
      testing.listen((event) async {
        print("Camera image length: ${event.length}");
        ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(event);
        ImageDescriptor descriptor = ImageDescriptor.raw(buffer, width: openCameraResult.width, height: openCameraResult.height, pixelFormat: PixelFormat.rgba8888);
        Codec x = await descriptor.instantiateCodec();
        FrameInfo y = await x.getNextFrame();
        PhotosManagerBase.instance.currentWebcamImage = y.image;
        print(DateTime.now());
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
