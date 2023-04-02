import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'capture_screen_view_model.g.dart';

class CaptureScreenViewModel = CaptureScreenViewModelBase with _$CaptureScreenViewModel;

abstract class CaptureScreenViewModelBase extends ScreenViewModelBase with Store {

  AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  CaptureScreenViewModelBase({
    required super.contextAccessor,
  });

}
