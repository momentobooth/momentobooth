import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/indicators/time_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';

part 'recording_countdown_screen_view_model.g.dart';

class RecordingCountdownScreenViewModel = RecordingCountdownScreenViewModelBase with _$RecordingCountdownScreenViewModel;

abstract class RecordingCountdownScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;

  @observable
  RecState recState = RecState.pre;

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;

  double get collageAspectRatio => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  List<double> snapshotTimes = [2.5, 5.0, 7.5, 10.0];

  final GlobalKey<TimeCounterState> timerKey = GlobalKey<TimeCounterState>();

  @observable
  bool showCounter = true;

  @observable
  bool showSpinner = false;

  final Completer<void> completer = Completer<void>();

  void collageReady() {
    completer.complete();
  }

  RecordingCountdownScreenViewModelBase({
    required super.contextAccessor,
  }) {
    getIt<PhotosManager>().photos.clear();
    Future.delayed(Duration(seconds: 15), onCaptureFinished);
  }

  Future<void> takeSnapshot() async {
    final capturer = LiveViewStreamSnapshotCapturer();
    getIt<PhotosManager>().photos.add(await capturer.captureAndGetPhoto());
  }

  Future<void> onCounterFinished() async {
    timerKey.currentState?.startTimer();
    recState = RecState.recording;
    showCounter = false;

    for (final t in snapshotTimes) {
      int seconds = t.floor();
      int milliseconds = ((t - seconds)*1000).round();
      Future.delayed(Duration(seconds: seconds, milliseconds: milliseconds), takeSnapshot);
    }
  }

  Future<void> onCaptureFinished() async {
    // Todo
    captureComplete = true;
    // navigateAfterCapture();
    recState = RecState.post;
    showSpinner = true;
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) return;
    getIt<StatsManager>().addCreatedSinglePhoto();
    router.go(ShareScreen.defaultRoute);
  }

}

enum RecState { pre, recording, post }
