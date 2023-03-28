import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'start_screen_view_model.g.dart';

class StartScreenViewModel = StartScreenViewModelBase with _$StartScreenViewModel;

abstract class StartScreenViewModelBase extends ScreenViewModelBase with Store {

}
