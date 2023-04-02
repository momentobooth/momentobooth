import 'package:flutter/animation.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'capture_screen_view_model.g.dart';

class CaptureScreenViewModel = CaptureScreenViewModelBase with _$CaptureScreenViewModel;

abstract class CaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  final int counterStart = 2;

  @observable
  bool showFlash = false;

  @computed
  double get opacity => showFlash ? 1.0 : 0.0;

  @computed
  Curve get flashAnimationCurve => Curves.easeOutQuart;

  @computed
  Duration get flashAnimationDuration => showFlash ? const Duration(milliseconds: 50) : const Duration(milliseconds: 2500);

  CaptureScreenViewModelBase({
    required super.contextAccessor,
  });

  void onCounterFinished() async {
    showFlash = true;
    await Future.delayed(flashAnimationDuration);
    showFlash = false;
  }

}
