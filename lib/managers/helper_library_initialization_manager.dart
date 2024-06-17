import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/src/rust/api/initialization.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:talker/talker.dart';

part 'helper_library_initialization_manager.g.dart';

class HelperLibraryInitializationManager = HelperLibraryInitializationManagerBase with _$HelperLibraryInitializationManager;

/// Class containing global state for photos in the app
abstract class HelperLibraryInitializationManagerBase with Store, Logger {

  Future initialize() async {
    await RustLib.init();

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
  }

}
