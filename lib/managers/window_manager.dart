import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:window_manager/window_manager.dart';

part 'window_manager.g.dart';

class WindowManager = WindowManagerBase with _$WindowManager;

abstract class WindowManagerBase with Store, Logger, Subsystem {

  bool _isFullScreen = false;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    _isFullScreen = await windowManager.isFullScreen();
  }

  // /////// //
  // Methods //
  // /////// //

  @action
  void toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    logDebug("Setting fullscreen to $_isFullScreen");
    windowManager.setFullScreen(_isFullScreen);
  }

}
