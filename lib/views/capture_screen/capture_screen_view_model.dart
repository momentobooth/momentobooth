import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/views/share_screen/share_screen.dart';

part 'capture_screen_view_model.g.dart';

class CaptureScreenViewModel = CaptureScreenViewModelBase with _$CaptureScreenViewModel;

abstract class CaptureScreenViewModelBase extends ScreenViewModelBase with Store, UiLoggy {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;
  static const flashStartDuration = Duration(milliseconds: 50);
  static const flashEndDuration = Duration(milliseconds: 2500);
  static const minimumContinueWait = Duration(milliseconds: 1500);

  int get counterStart => SettingsManager.instance.settings.captureDelaySeconds;

  double get collageAspectRatio => SettingsManager.instance.settings.collageAspectRatio;
  double get collagePadding => SettingsManager.instance.settings.collagePadding;

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
  
  /// Global key for controlling the slider widget.
  final GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  final Completer<void> completer = Completer<void>();

  void collageReady() {
    completer.complete();
  }

  Future<File?> captureCollage() async {
    PhotosManager.instance.chosen.clear();
    PhotosManager.instance.chosen.add(0);
    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManager.instance.settings.output.resolutionMultiplier;
    final format = SettingsManager.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManager.instance.settings.output.jpgQuality;
    await completer.future;
    PhotosManager.instance.outputImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');
    
    return await PhotosManager.instance.writeOutput();
  }

  CaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    capturer = switch (SettingsManager.instance.settings.hardware.captureMethod) {
      CaptureMethod.sonyImagingEdgeDesktop => SonyRemotePhotoCapture(SettingsManager.instance.settings.hardware.captureLocation),
      CaptureMethod.liveViewSource => LiveViewStreamSnapshotCapturer(),
      CaptureMethod.gPhoto2 => LiveViewManager.instance.gPhoto2Camera,
    } as PhotoCaptureMethod;
    Future.delayed(photoDelay).then((_) => captureAndGetPhoto());
  }

  String get outputFolder => SettingsManager.instance.settings.output.localFolder;

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
      StatsManager.instance.addCapturedPhoto();
      PhotosManager.instance.photos.add(image);
      if (SettingsManager.instance.settings.singlePhotoIsCollage) {
        await captureCollage();
      } else {
        PhotosManager.instance.outputImage = image;
        await PhotosManager.instance.writeOutput();
      }
    } catch (error) {
      loggy.warning(error);
      final errorFile = File('assets/bitmap/capture-error.png');
      PhotosManager.instance.outputImage = await errorFile.readAsBytes();
    } finally {
      captureComplete = true;
      navigateAfterCapture();
    }
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) return;
    StatsManager.instance.addCreatedSinglePhoto();
    router.go(ShareScreen.defaultRoute);
  }

}
