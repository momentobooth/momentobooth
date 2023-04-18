import 'package:flutter/animation.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:mobx/mobx.dart';

part 'multi_capture_screen_view_model.g.dart';

class MultiCaptureScreenViewModel = MultiCaptureScreenViewModelBase with _$MultiCaptureScreenViewModel;

abstract class MultiCaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;
  static const flashStartDuration = Duration(milliseconds: 50);
  static const flashEndDuration = Duration(milliseconds: 2500);

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
    await Future.delayed(flashAnimationDuration);
    flashComplete = true;
    navigateAfterCapture();
  }

  void captureAndGetPhoto() async {
    final image = await capturer.captureAndGetPhoto();
    PhotosManagerBase.instance.photos.add(image);
    captureComplete = true;
    // Fixme, should be replaced with the output of the collage later.
    PhotosManagerBase.instance.outputImage = image;
    navigateAfterCapture();
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) { return; }
    if (PhotosManagerBase.instance.photos.length >= maxPhotos) {
      router.push("/collage-maker");
    } else {
      router.push("/multi-capture");
    }
  }

}
