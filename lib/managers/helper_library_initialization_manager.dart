import 'dart:async';

import 'package:loggy/loggy.dart' as loggy;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

part 'helper_library_initialization_manager.g.dart';

class HelperLibraryInitializationManager extends _HelperLibraryInitializationManagerBase with _$HelperLibraryInitializationManager {

  static final HelperLibraryInitializationManager instance = HelperLibraryInitializationManager._internal();

  HelperLibraryInitializationManager._internal();

}

/// Class containing global state for photos in the app
abstract class _HelperLibraryInitializationManagerBase with Store {

  final Completer<bool> _nokhwaInitializationResultCompleter = Completer<bool>();
  final Completer<bool> _gphoto2InitializationResultCompleter = Completer<bool>();

  Future<bool> get nokhwaInitializationResult => _nokhwaInitializationResultCompleter.future;
  Future<bool> get gphoto2InitializationResult => _gphoto2InitializationResultCompleter.future;

  @readonly
  String? _nokhwaInitializationMessage;

  @readonly
  String? _gphoto2InitializationMessage;

  void initialize() {
    rustLibraryApi.initializeLog().listen(_processLogEvent);
    rustLibraryApi.initializeHardware().listen(_processHardwareInitEvent);
  }

  void _processLogEvent(LogEvent event) {
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

  void _processHardwareInitEvent(HardwareInitializationFinishedEvent event) {
    switch (event.step) {
      case HardwareInitializationStep.Nokhwa:
        _nokhwaInitializationMessage = event.message;
        _nokhwaInitializationResultCompleter.complete(event.hasSucceeded);
        loggy.logInfo("Nokhwa initialization finished with result: ${event.hasSucceeded} and message: ${event.message}");
      case HardwareInitializationStep.Gphoto2:
        _gphoto2InitializationMessage = event.message;
        _gphoto2InitializationResultCompleter.complete(event.hasSucceeded);
        loggy.logInfo("gPhoto2 initialization finished with result: ${event.hasSucceeded} and message: ${event.message}");
    }
  }

}
