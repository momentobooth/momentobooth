import 'dart:async';
import 'dart:io';

import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/models/hotkey_action.dart';

part 'hotkey_manager.g.dart';

class HotkeyManager extends _HotkeyManagerBase with _$HotkeyManager {

  static final HotkeyManager instance = HotkeyManager._internal();

  HotkeyManager._internal();

}

abstract class _HotkeyManagerBase with Store, UiLoggy {

  final StreamController<HotkeyAction> _hotkeyActionSubject = StreamController<HotkeyAction>();

  Stream<HotkeyAction> get hotkeyActionStream => _hotkeyActionSubject.stream;

  // ////////////// //
  // Initialization //
  // ////////////// //

  KeyModifier get _defaultModifier => Platform.isMacOS ? KeyModifier.meta : KeyModifier.control;

  Future<void> initialize() async {
    await hotKeyManager.unregisterAll();

    // Ctrl + H navigate to home screen
    await hotKeyManager.register(
      HotKey(
        KeyCode.keyH,
        modifiers: [_defaultModifier],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) => _hotkeyActionSubject.add(HotkeyAction.goToHomeScreen),
    );
    // Ctrl + S opens/closes settings
    await hotKeyManager.register(
      HotKey(
        KeyCode.keyS,
        modifiers: [_defaultModifier],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) => _hotkeyActionSubject.add(HotkeyAction.openSettingsScreen),
    );
    // Ctrl + M opens manual collage maker screen
    await hotKeyManager.register(
      HotKey(
        KeyCode.keyM,
        modifiers: [_defaultModifier],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) => _hotkeyActionSubject.add(HotkeyAction.openManualCollageScreen),
    );
    // Alt + Enter toggles full-screen
    await hotKeyManager.register(
      HotKey(
        KeyCode.enter,
        modifiers: [KeyModifier.alt],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) => WindowManager.instance.toggleFullscreen(),
    );
    // Ctrl + F toggles full-screen
    await hotKeyManager.register(
      HotKey(
        KeyCode.keyF,
        modifiers: [_defaultModifier],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (hotKey) => WindowManager.instance.toggleFullscreen(),
    );
  }

  // /////// //
  // Methods //
  // /////// //

}
