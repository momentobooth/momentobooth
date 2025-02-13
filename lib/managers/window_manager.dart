import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:window_manager/window_manager.dart';

part 'window_manager.g.dart';

class WindowManager = WindowManagerBase with _$WindowManager;

abstract class WindowManagerBase extends Subsystem with Store, Logger {

  @readonly
  bool _isFullScreen = false;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    _isFullScreen = await windowManager.isFullScreen();
    setTitle("");
  }

  // /////// //
  // Methods //
  // /////// //

  void setTitle(String title) {
    if (title.isEmpty) {
      windowManager.setTitle("MomentoBooth");
    } else {
      windowManager.setTitle("$title – MomentoBooth");
    }
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

  void close() {
    windowManager.close();
  }

}
