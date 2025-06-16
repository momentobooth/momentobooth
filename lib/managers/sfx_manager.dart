import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/logger.dart';

part 'sfx_manager.g.dart';

class SfxManager = SfxManagerBase with _$SfxManager;

abstract class SfxManagerBase extends Subsystem with Store, Logger {

  AudioPlayer? _audioPlayer;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Future<void> initialize() async {
    // Linux: Uses just_audio_media_kit.
    // Windows: Uses just_audio_windows. Not init needed.
    // macOS: Uses native implementation of just_audio. No init needed.
    JustAudioMediaKit.ensureInitialized(windows: false);

    AudioPlayer audioPlayer = AudioPlayer(handleInterruptions: false);
    await audioPlayer.setAsset('assets/sounds/silence.ogg'); // This is a hack to make sure the audio player is initialized
    await audioPlayer.play();

    _audioPlayer = audioPlayer;
  }

  // ////////////// //
  // Public methods //
  // ////////////// //

  Future<void> playSampleSound() async {
    String filePath = 'assets/sounds/audio_test.mp3';

    await _playSoundFromAsset(filePath);
  }

  Future<void> playShareScreenSound() async {
    String filePath = getIt<SettingsManager>().settings.ui.shareScreenSfxFile;

    await _playSound(filePath);
  }

  Future<void> playClickSound() async {
    String filePath = getIt<SettingsManager>().settings.ui.clickSfxFile;

    await _playSound(filePath);
  }

  // ////////////// //
  // Helper methods //
  // ////////////// //

  Future<void> _playSoundFromAsset(String assetPath) async {
    try {
      if (!getIt<SettingsManager>().settings.ui.enableSfx || assetPath.isEmpty) return;
      await _audioPlayer?.stop();
      await _audioPlayer?.setAsset(assetPath);
      await _audioPlayer?.play();
    } catch (e) {
      logError("Error playing asset sound ($assetPath): $e");
    }
  }

  Future<void> _playSound(String filePath) async {
    try {
      if (!getIt<SettingsManager>().settings.ui.enableSfx || filePath.isEmpty) return;
      await _audioPlayer?.stop();
      await _audioPlayer?.setFilePath(filePath);
      await _audioPlayer?.play();
    } catch (e) {
      logError("Error playing sound ($filePath): $e");
    }
  }

}
