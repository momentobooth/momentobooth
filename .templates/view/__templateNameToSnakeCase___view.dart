import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/__templateNameToSnakeCase__/__templateNameToSnakeCase___controller.dart';
import 'package:momento_booth/views/__templateNameToSnakeCase__/__templateNameToSnakeCase___view_model.dart';

class __templateNameToPascalCase__View extends ScreenViewBase<__templateNameToPascalCase__ViewModel, __templateNameToPascalCase__Controller> {

  const __templateNameToPascalCase__View({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Text("Hello from __templateNameToPascalCase__!");
  }

}
