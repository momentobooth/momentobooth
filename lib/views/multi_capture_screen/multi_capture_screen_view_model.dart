import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/multi_capture_screen/multi_capture_screen.dart';

part 'multi_capture_screen_view_model.g.dart';

class MultiCaptureScreenViewModel = MultiCaptureScreenViewModelBase with _$MultiCaptureScreenViewModel;

abstract class MultiCaptureScreenViewModelBase extends ScreenViewModelBase with Store, UiLoggy {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;
  static const flashStartDuration = Duration(milliseconds: 50);
  static const flashEndDuration = Duration(milliseconds: 2500);
  static const minimumContinueWait = Duration(milliseconds: 1500);

  int get counterStart => SettingsManagerBase.instance.settings.captureDelaySeconds;

  @computed
  Duration get photoDelay => Duration(seconds: counterStart) - capturer.captureDelay + flashStartDuration;

  @observable
  bool showCounter = true;

  @observable
  bool showFlash = false;

  @computed
  double get opacity => showFlash ? 1.0 : 0.0;

  @computed
  Curve get flashAnimationCurve => Curves.easeOutQuart;

  @computed
  Duration get flashAnimationDuration => showFlash ? flashStartDuration : flashEndDuration;

  @computed
  int get photoNumber => PhotosManagerBase.instance.photos.length+1;

  final int maxPhotos = 4;

  MultiCaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    if (SettingsManagerBase.instance.settings.hardware.captureMethod == CaptureMethod.sonyImagingEdgeDesktop){
      capturer = SonyRemotePhotoCapture(SettingsManagerBase.instance.settings.hardware.captureLocation);
  	} else {
      capturer = LiveViewStreamSnapshotCapturer();
    }
    Future.delayed(photoDelay).then((_) => captureAndGetPhoto());
  }

  void onCounterFinished() async {
    showFlash = true;
    showCounter = false;
    await Future.delayed(flashAnimationDuration);
    showFlash = false;
    await Future.delayed(minimumContinueWait);
    flashComplete = true; // Flash is now not actually complete, but after this time we do not care about it anymore.
    navigateAfterCapture();
  }

  void captureAndGetPhoto() async {
    try {
      final image = await capturer.captureAndGetPhoto();
      StatsManagerBase.instance.addCapturedPhoto();
      PhotosManagerBase.instance.photos.add(image);
    } catch (error) {
      loggy.warning(error);
      final errorFile = File('assets/bitmap/capture-error.png');
      PhotosManagerBase.instance.photos.add(await errorFile.readAsBytes());
    } finally {
      captureComplete = true;
      navigateAfterCapture();
    }
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) return;
    if (PhotosManagerBase.instance.photos.length >= maxPhotos) {
      router.go(CollageMakerScreen.defaultRoute);
    } else {
      router.go("${MultiCaptureScreen.defaultRoute}?n=${PhotosManagerBase.instance.photos.length}");
    }
  }

}
