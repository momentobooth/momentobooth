import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

part 'window_manager.g.dart';

class WindowManager extends _WindowManagerBase with _$WindowManager {

  static final WindowManager instance = WindowManager._internal();

  WindowManager._internal();

}

abstract class _WindowManagerBase with Store, Logger {

  bool _isFullScreen = false;

  // ////////////// //
  // Initialization //
  // ////////////// //

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
