import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/src/rust/api/sfx.dart' as rust_sfx;
import 'package:momento_booth/utils/logger.dart';
import 'package:synchronized/synchronized.dart';

part 'sfx_manager.g.dart';

class SfxManager = SfxManagerBase with _$SfxManager;

abstract class SfxManagerBase extends Subsystem with Store, Logger {

  final Lock _updateMqttClientInstanceLock = Lock();
  static const int _testSoundId = 0, _clickSoundId = 1, _shareScreenSoundId = 2;

  bool get _isSfxEnabled => getIt<SettingsManager>().settings.ui.enableSfx;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Future<void> initialize() async {
    await rust_sfx.initialize();
    await _loadSoundFromAsset(_testSoundId, 'assets/sounds/audio_test.mp3');

    autorun((_) {
      String clickSoundPath = getIt<SettingsManager>().settings.ui.clickSfxFile;
      String shareScreenSoundPath = getIt<SettingsManager>().settings.ui.shareScreenSfxFile;

      _updateMqttClientInstanceLock.synchronized(() async {
        await _loadSoundFromFile(_clickSoundId, clickSoundPath);
        await _loadSoundFromFile(_shareScreenSoundId, shareScreenSoundPath);
      });
    });
  }

  // ////////////// //
  // Public methods //
  // ////////////// //

  Future<void> playSampleSound() async {
    await rust_sfx.playAudioIfLoaded(id: _testSoundId);
  }

  Future<void> playClickSound() async {
    if (_isSfxEnabled) await rust_sfx.playAudioIfLoaded(id: _clickSoundId);
  }

  Future<void> playShareScreenSound() async {
    if (_isSfxEnabled) await rust_sfx.playAudioIfLoaded(id: _shareScreenSoundId);
  }

  // ///////////// //
  // Sound loading //
  // ///////////// //`

  Future<void> _loadSoundFromFile(int id, String filePath) async {
    if (filePath.isEmpty) {
      await rust_sfx.clearAudio(id: id);
    } else {
      Uint8List data = await File(filePath).readAsBytes();
      await rust_sfx.loadAudio(id: id, rawAudioData: data);
    }
  }

  Future<void> _loadSoundFromAsset(int id, String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    await rust_sfx.loadAudio(id: id, rawAudioData: data.buffer.asUint8List());
  }

}
