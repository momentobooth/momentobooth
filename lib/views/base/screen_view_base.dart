import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/stateless_widget_base.dart';

abstract class ScreenViewBase<TViewModel extends ScreenViewModelBase, TController extends ScreenControllerBase<TViewModel>> extends StatelessWidgetBase {

  final TViewModel viewModel;
  final TController controller;

  const ScreenViewBase({
    super.key, 
    required this.viewModel,
    required this.controller,
  });

}
