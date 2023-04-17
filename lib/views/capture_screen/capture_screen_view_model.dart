import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:flutter_rust_bridge_example/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/photo_collage.dart';
import 'package:mobx/mobx.dart';

part 'capture_screen_view_model.g.dart';

class CaptureScreenViewModel = CaptureScreenViewModelBase with _$CaptureScreenViewModel;

abstract class CaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  late final PhotoCaptureMethod capturer;
  bool flashComplete = false;
  bool captureComplete = false;

  int get counterStart => SettingsManagerBase.instance.settings.captureDelaySeconds;

  @computed
  Duration get photoDelay => Duration(seconds: counterStart) - capturer.captureDelay;

  @observable
  bool showCounter = true;

  @observable
  bool showFlash = false;

  @computed
  double get opacity => showFlash ? 1.0 : 0.0;

  @computed
  Curve get flashAnimationCurve => Curves.easeOutQuart;

  @computed
  Duration get flashAnimationDuration => showFlash ? const Duration(milliseconds: 50) : const Duration(milliseconds: 2500);
  
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
    print('captureCollage() executed in ${stopwatch.elapsed}');
    print("Written collage image to output image memory");
    
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
    await Future.delayed(flashAnimationDuration);
    flashComplete = true;
    navigateAfterCapture();
  }

  void captureAndGetPhoto() async {
    final image = await capturer.captureAndGetPhoto();
    PhotosManagerBase.instance.photos.add(image);
    // PhotosManagerBase.instance.outputImage = image;
    await captureCollage();
    captureComplete = true;
    navigateAfterCapture();
  }

  void navigateAfterCapture() {
    if (!flashComplete || !captureComplete) { return; }
    router.push("/share");
  }

}
