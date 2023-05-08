import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';

class ManualCollageScreenView extends ScreenViewBase<ManualCollageScreenViewModel, ManualCollageScreenController> {

  const ManualCollageScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Text("Hello from ManualCollageScreen!");
  }

}
