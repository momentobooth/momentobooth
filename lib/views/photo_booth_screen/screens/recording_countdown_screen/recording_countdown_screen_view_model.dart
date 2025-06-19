import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/indicators/time_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

part 'recording_countdown_screen_view_model.g.dart';

class RecordingCountdownScreenViewModel = RecordingCountdownScreenViewModelBase with _$RecordingCountdownScreenViewModel;

abstract class RecordingCountdownScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;

  @observable
  RecState recState = RecState.pre;

  int get recLength => getIt<SettingsManager>().settings.debug.videoDuration;

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;

  double get collageAspectRatio => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

  int get preRecordDelayMs => getIt<SettingsManager>().settings.debug.videoPreRecordDelayMs; // ms to start camera capture before advertised time
  int get postRecordDelayMs => getIt<SettingsManager>().settings.debug.videoPostRecordDelayMs; // ms to end camera capture after advertised time

  List<double> get snapshotTimes => [recLength*0.25, recLength*0.5, recLength*0.75, recLength*1.0];

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
    getIt<PhotosManager>().startVideoProcess();

    Future.delayed(Duration(seconds: counterStart, milliseconds: -preRecordDelayMs), startCameraCapture);
    Future.delayed(Duration(seconds: counterStart + recLength, milliseconds: postRecordDelayMs), stopCameraCapture);
    Future.delayed(Duration(seconds: counterStart), onCaptureStart);
    Future.delayed(Duration(seconds: counterStart + recLength), onCaptureFinished);
  }

  void startCameraCapture() {
    if (getIt<LiveViewManager>().gPhoto2Camera == null) {
      logError("gPhoto2Camera not initialized");
      router.go(StartScreen.defaultRoute);
      return;
    }
    getIt<LiveViewManager>().gPhoto2Camera!.startVideoRecording();
  }

  void stopCameraCapture() {
    if (getIt<LiveViewManager>().gPhoto2Camera == null) {
      logError("gPhoto2Camera not initialized");
      router.go(StartScreen.defaultRoute);
      return;
    }
    getIt<LiveViewManager>().gPhoto2Camera!.stopVideoRecording();
  }

  void onCaptureStart() {
    getIt<PhotosManager>().recordAudio();
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
