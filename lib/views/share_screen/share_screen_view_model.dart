import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view.dart';
import 'package:mobx/mobx.dart';

part 'share_screen_view_model.g.dart';

class ShareScreenViewModel = ShareScreenViewModelBase with _$ShareScreenViewModel;

enum UploadState {
  notStarted,
  uploading,
  errored,
  done
}

abstract class ShareScreenViewModelBase extends ScreenViewModelBase with Store {

  ShareScreenViewModelBase({
    required super.contextAccessor,
  });

  Uint8List get outputImage => PhotosManagerBase.instance.outputImage!;

  @observable
  String qrText = "Get QR";

  @observable
  UploadState uploadState = UploadState.notStarted;

  @observable
  bool qrShown = false;

  @observable
  String qrUrl = "";

  CaptureMode get captureMode => PhotosManagerBase.instance.captureMode;
  String get backText => captureMode == CaptureMode.single ? "Retake" : "Change";

  /// Global key for controlling the slider widget.
  GlobalKey<SliderWidgetState> sliderKey = GlobalKey<SliderWidgetState>();

}
