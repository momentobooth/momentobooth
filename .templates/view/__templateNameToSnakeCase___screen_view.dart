import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/__templateNameToSnakeCase___screen/__templateNameToSnakeCase___screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/__templateNameToSnakeCase___screen/__templateNameToSnakeCase___screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';

class __templateNameToPascalCase__ScreenView extends ScreenViewBase<__templateNameToPascalCase__ScreenViewModel, __templateNameToPascalCase__ScreenController> {

  const __templateNameToPascalCase__ScreenView({
    super.key,
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Text("Hello from __templateNameToPascalCase__ Screen!");
  }

}
