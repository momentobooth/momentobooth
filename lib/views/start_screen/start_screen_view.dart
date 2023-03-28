
import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';

class StartScreenView extends ScreenViewBase<StartScreenViewModel, StartScreenController> {

  const StartScreenView({
    super.key,
    required super.viewModel,
    required super.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        SampleBackground(),
        Text("Hello World!"),
      ],
    );
  }

}
