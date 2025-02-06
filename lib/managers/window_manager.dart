import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:window_manager/window_manager.dart';

part 'window_manager.g.dart';

class WindowManager = WindowManagerBase with _$WindowManager;

abstract class WindowManagerBase with Store, Logger, Subsystem {

  @readonly
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

  void setTitle(String title) {
    windowManager.setTitle("$title – MomentoBooth");
  }

  void toggleFullscreen() {
    setFullscreen(!_isFullScreen);
  }

  @action
  void setFullscreen(bool fullscreen) {
    _isFullScreen = fullscreen;
    logDebug("Setting fullscreen to $_isFullScreen");
    windowManager.setFullScreen(_isFullScreen);
  }

}
