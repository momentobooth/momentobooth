import 'package:flutter/animation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';

part 'multi_capture_screen_view_model.g.dart';

class MultiCaptureScreenViewModel = MultiCaptureScreenViewModelBase with _$MultiCaptureScreenViewModel;

abstract class MultiCaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;
  double get aspectRatio => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;

  PhotosManager get photosManager => getIt<PhotosManager>();

  @observable
  bool showCounter = true;

  @observable
  bool showFlash = false;

  @observable
  bool showSpinner = false;

  @computed
  double get opacity => showFlash ? 1.0 : 0.0;

  @computed
  Curve get flashAnimationCurve => Curves.easeOutQuart;

  @computed
  Duration get flashAnimationDuration => showFlash ? flashStartDuration : flashEndDuration;

  @computed
  int get photoNumber => getIt<PhotosManager>().photos.length+1;

  final int maxPhotos = getIt<ProjectManager>().settings.collageMode.captureCount;

  MultiCaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    getIt<PhotosManager>().initiateDelayedPhotoCapture(onCaptureFinished);
  }

  Future<void> onCounterFinished() async {
    showFlash = true;
    showCounter = false;
    await Future.delayed(flashAnimationDuration);
    showFlash = false;
    showSpinner = true;
    await Future.delayed(minimumContinueWait);
    flashComplete = true; // Flash is now not actually complete, but after this time we do not care about it anymore.
    navigateAfterCapture();
  }

  void onCaptureFinished() {
    captureComplete = true;
    navigateAfterCapture();
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) return;
    if (getIt<PhotosManager>().photos.length >= maxPhotos) {
      router.go(CollageMakerScreen.defaultRoute);
    } else {
      router.go("${MultiCaptureScreen.defaultRoute}?n=${getIt<PhotosManager>().photos.length}");
    }
  }

}
