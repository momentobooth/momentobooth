import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/shader_viewer.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_controller.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_view_model.dart';

class NotAvailableScreenView extends ScreenViewBase<NotAvailableScreenViewModel, NotAvailableScreenController> {

  const NotAvailableScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return ShaderViewer(assetKey: 'assets/shaders/starfield-dots.frag', timeDilation: 5);
  }

}
