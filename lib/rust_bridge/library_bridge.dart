import 'dart:ffi';
import 'dart:io';

import 'package:momento_booth/managers/native_library_initialization_manager.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';

const _base = 'momento_booth_native_helpers';
final _path = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';
final _dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(_path);

final rustLibraryApi = MomentoBoothNativeHelpersImpl(_dylib);

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

  }
}
