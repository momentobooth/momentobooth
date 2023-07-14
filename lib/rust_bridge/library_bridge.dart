import 'dart:ffi';
import 'dart:io';

import 'package:loggy/loggy.dart' as loggy;
import 'package:momento_booth/managers/native_library_initialization_manager.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';

const _base = 'momento_booth_native_helpers';
final _path = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';
final _dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(_path);

final rustLibraryApi = MomentoBoothNativeHelpersImpl(_dylib);

Future<void> init() async {
  // Initialize log
  rustLibraryApi.initializeLog().listen(processLogEvent);

  // Initialize hardware
  rustLibraryApi.initializeHardware().listen(processHardwareInitEvent);
}

void processLogEvent(LogEvent event) {
  switch (event.level) {
    case LogLevel.Debug:
      loggy.logDebug("Lib: ${event.message}");
    case LogLevel.Info:
      loggy.logInfo("Lib: ${event.message}");
    case LogLevel.Warning:
      loggy.logWarning("Lib: ${event.message}");
    case LogLevel.Error:
      loggy.logError("Lib: ${event.message}");
  }
}

void processHardwareInitEvent(HardwareInitializationFinishedEvent event) {
  switch (event.step) {
    
    case HardwareInitializationStep.Nokhwa:
      HardwareStateManager.instance.nokhwaIsInitialized = event.hasSucceeded;
      HardwareStateManager.instance.nokhwaInitializationMessage = event.message;
    case HardwareInitializationStep.Gphoto2:
      loggy.logDebug("Gphoto2 init: ${event.hasSucceeded} - ${event.message}");

  }
}
