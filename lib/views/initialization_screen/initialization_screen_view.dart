import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_controller.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_view_model.dart';

class InitializationScreenView extends ScreenViewBase<InitializationScreenViewModel, InitializationScreenController> {

  const InitializationScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Text("Hello from InitializationScreen!");
  }

}
