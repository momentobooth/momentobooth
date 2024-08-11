import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/src/rust/api/initialization.dart';
import 'package:momento_booth/src/rust/helpers.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:talker/talker.dart';

part 'helper_library_initialization_manager.g.dart';

class HelperLibraryInitializationManager extends _HelperLibraryInitializationManagerBase with _$HelperLibraryInitializationManager {

  static final HelperLibraryInitializationManager instance = HelperLibraryInitializationManager._internal();

  HelperLibraryInitializationManager._internal();

}

/// Class containing global state for photos in the app
abstract class _HelperLibraryInitializationManagerBase with Store, Logger {

  final Completer<bool> _nokhwaInitializationResultCompleter = Completer<bool>();
  final Completer<bool> _gphoto2InitializationResultCompleter = Completer<bool>();

  Future<bool> get nokhwaInitializationResult => _nokhwaInitializationResultCompleter.future;
  Future<bool> get gphoto2InitializationResult => _gphoto2InitializationResultCompleter.future;

  @readonly
  String? _nokhwaInitializationMessage;

  @readonly
  String? _gphoto2InitializationMessage;

  Future initialize() async {
    Talker talker = getIt<Talker>();
    setupLogStream().listen((msg) {
      LogLevel logLevel = switch (msg.logLevel) {
        Level.error => LogLevel.error,
        Level.warn => LogLevel.warning,
        Level.info => LogLevel.info,
        Level.debug => LogLevel.debug,
        Level.trace => LogLevel.verbose,
      };
      talker.log("Lib: ${msg.lbl} - ${msg.msg}", logLevel: logLevel);
    });
    initializeHardware().listen(_processHardwareInitEvent);
  }

  void _processHardwareInitEvent(HardwareInitializationFinishedEvent event) {
    switch (event.step) {
      case HardwareInitializationStep.nokhwa:
        _nokhwaInitializationMessage = event.message;
        _nokhwaInitializationResultCompleter.complete(event.hasSucceeded);
        logInfo("Nokhwa initialization finished with result: ${event.hasSucceeded} and message: ${event.message}");
      case HardwareInitializationStep.gphoto2:
        _gphoto2InitializationMessage = event.message;
        _gphoto2InitializationResultCompleter.complete(event.hasSucceeded);
        logInfo("gPhoto2 initialization finished with result: ${event.hasSucceeded} and message: ${event.message}");
    }
  }

}
