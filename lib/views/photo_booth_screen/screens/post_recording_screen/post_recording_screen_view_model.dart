import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

part 'post_recording_screen_view_model.g.dart';

class PostRecordingScreenViewModel = PostRecordingScreenViewModelBase with _$PostRecordingScreenViewModel;

abstract class PostRecordingScreenViewModelBase extends ScreenViewModelBase with Store {

  final Completer<void> completer = Completer<void>();

  void collageReady() {
    completer.complete();
  }

  PostRecordingScreenViewModelBase({
    required super.contextAccessor,
  }) {

  }

  void navigate() {
    // if (!flashComplete || !captureComplete) return;
    router.go(StartScreen.defaultRoute);
  }

}

enum RecState { pre, recording, post }
