import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
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
  
  /// Global key for controlling the slider widget.
  final GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  Future<File?> captureCollage() async {
    PhotosManagerBase.instance.chosen.clear();
    PhotosManagerBase.instance.chosen.add(0);
    final stopwatch = Stopwatch()..start();
    final pixelRatio = SettingsManagerBase.instance.settings.output.resolutionMultiplier;
    final format = SettingsManagerBase.instance.settings.output.exportFormat;
    final jpgQuality = SettingsManagerBase.instance.settings.output.jpgQuality;
    await Future.delayed(Duration(milliseconds: 100));
    PhotosManagerBase.instance.outputImage = await collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');
    
    return await PhotosManagerBase.instance.writeOutput();
  }

  CaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    if (SettingsManagerBase.instance.settings.hardware.captureMethod == CaptureMethod.sonyImagingEdgeDesktop){
      capturer = SonyRemotePhotoCapture(SettingsManagerBase.instance.settings.hardware.captureLocation);
  	} else {
      capturer = LiveViewStreamSnapshotCapturer();
    }
    Future.delayed(photoDelay).then((_) => captureAndGetPhoto());
  }

  String get outputFolder => SettingsManagerBase.instance.settings.output.localFolder;

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
    final image = await capturer.captureAndGetPhoto();
    PhotosManagerBase.instance.photos.add(image);
    if (SettingsManagerBase.instance.settings.singlePhotoIsCollage) {
      await captureCollage();
    } else {
      PhotosManagerBase.instance.outputImage = image;
      await PhotosManagerBase.instance.writeOutput();
    }
    captureComplete = true;
    navigateAfterCapture();
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) { return; }
    router.go(ShareScreen.defaultRoute);
  }

}
