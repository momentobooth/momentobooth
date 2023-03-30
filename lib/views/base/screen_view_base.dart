import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_abstractor.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:flutter_rust_bridge_example/views/base/stateless_widget_base.dart';

abstract class ScreenViewBase<TViewModel extends ScreenViewModelBase, TController extends ScreenControllerBase<TViewModel>> extends StatelessWidgetBase with BuildContextAbstractor {

  final TViewModel viewModel;
  final TController controller;

  @override
  final BuildContextAccessor contextAccessor;
  
  BuildContext get context => contextAccessor.buildContext;

  const ScreenViewBase({
    super.key,
    required this.viewModel,
    required this.controller,
    required this.contextAccessor,
  });

  @override
  Widget build(BuildContext context) {
    contextAccessor.buildContext = context;
    return body;
  }

  Widget get body;

}
