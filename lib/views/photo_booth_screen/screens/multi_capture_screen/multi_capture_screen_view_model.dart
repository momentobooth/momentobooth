import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/constants.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

part 'multi_capture_screen_view_model.g.dart';

class MultiCaptureScreenViewModel = MultiCaptureScreenViewModelBase with _$MultiCaptureScreenViewModel;

abstract class MultiCaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;

  int get counterStart => getIt<SettingsManager>().settings.captureDelaySeconds;
  double get aspectRatio => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;

  double get collageAspectRatio => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePadding => getIt<SettingsManager>().settings.collagePadding;

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

  /// Global key for controlling the slider widget.
  final GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  final Completer<void> completer = Completer<void>();

  late final bool enablePhotoCollageWidget;

  void collageReady() {
    completer.complete();
  }

  Future<File?> captureCollage() async {
    final stopwatch = Stopwatch()..start();
    final pixelRatio = getIt<SettingsManager>().settings.output.resolutionMultiplier;
    final format = getIt<SettingsManager>().settings.output.exportFormat;
    final jpgQuality = getIt<SettingsManager>().settings.output.jpgQuality;
    await completer.future;
    getIt<PhotosManager>().outputImage = await collageKey.currentState!.getCollageImage(
      createdByMode: CreatedByMode.multi,
      pixelRatio: pixelRatio,
      format: format,
      jpgQuality: jpgQuality,
    );
    logDebug('captureCollage took ${stopwatch.elapsed}');

    return await getIt<PhotosManager>().writeOutput();
  }

  @computed
  int get capturedPhotos => getIt<PhotosManager>().photos.length;

  @computed
  int get photoNumber => min(maxPhotos, capturedPhotos + 1); // Technically the min is not needed as there are no observables attached. Still.

  final int maxPhotos = getIt<ProjectManager>().settings.collageMode.captureCount;

  MultiCaptureScreenViewModelBase({
    required super.contextAccessor,
  }) {
    getIt<PhotosManager>().initiateDelayedPhotoCapture(onCaptureFinished);
    enablePhotoCollageWidget = photoNumber == maxPhotos;
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
    // If we completed all captures, go to the next screen.
    if (getIt<PhotosManager>().photos.length >= maxPhotos) {
      // If the collage mode is user selection, go to the collage maker screen.
      if (getIt<ProjectManager>().settings.collageMode == CollageMode.userSelection) {
        router.go(CollageMakerScreen.defaultRoute);
      } else {
        // Otherwise, we can immediately create the collage and go to the share screen.
        getIt<PhotosManager>().chosen.clear();
        getIt<PhotosManager>().chosen.addAll(List.generate(getIt<PhotosManager>().photos.length, (index) => index));
        captureCollage().then((value) {
          if (value != null) {
            // Normally this statistic is handled in the CollageMakerScreen, but if we skip that screen we need to do it here.
            getIt<StatsManager>().addCreatedMultiCapturePhoto();
            router.go(ShareScreen.defaultRoute);
          } else {
            // Something went wrong, go back to start.
            router.go(StartScreen.defaultRoute);
          }
        });
      }
    } else {
      // Otherwise, go to a new MultiCaptureScreen to take the next photo.
      router.go("${MultiCaptureScreen.defaultRoute}?n=${getIt<PhotosManager>().photos.length}");
    }
  }

}
