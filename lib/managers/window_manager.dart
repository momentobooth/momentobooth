import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

part 'window_manager.g.dart';

class WindowManager = WindowManagerBase with _$WindowManager;

abstract class WindowManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Window manager";

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
  Future<void> setFullscreen(bool fullscreen) async {
    _isFullScreen = fullscreen;
    logDebug("Setting fullscreen to $_isFullScreen");
    if (!kIsWeb && Platform.isWindows && fullscreen && await windowManager.isMaximized()) {
      // Workaround issue on Windows where full screen is not really full screen if the app was maximized beforehand.
      await windowManager.unmaximize();
      await Future.delayed(Duration(milliseconds: 100)); // 1 ms also seems to work, just to be sure set to 100 ms.
    }
    await windowManager.setFullScreen(_isFullScreen);
  }

  void close() {
    windowManager.close();
  }

}
