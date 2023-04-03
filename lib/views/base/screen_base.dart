import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';

abstract class ScreenBase<TViewModel extends ScreenViewModelBase, TController extends ScreenControllerBase<TViewModel>, TView extends ScreenViewBase<TViewModel, TController>> extends StatefulWidget {

  const ScreenBase({super.key});

  TController createController({required TViewModel viewModel, required BuildContextAccessor contextAccessor});

  TViewModel createViewModel({required BuildContextAccessor contextAccessor});

  TView createView({required TController controller, required TViewModel viewModel, required BuildContextAccessor contextAccessor});

  @override
  State<StatefulWidget> createState() => _ScreenBaseState();

}

class _ScreenBaseState<TViewModel extends ScreenViewModelBase, TController extends ScreenControllerBase<TViewModel>, TView extends ScreenViewBase<TViewModel, TController>> extends State<ScreenBase<TViewModel, TController, TView>> {

  late TController _controller;
  late TViewModel _viewModel;
  late TView _view;
  late BuildContextAccessor _contextAccessor;

  @override
  void initState() {
    _contextAccessor = BuildContextAccessor();
    _viewModel = widget.createViewModel(contextAccessor: _contextAccessor);
    _controller = widget.createController(viewModel: _viewModel, contextAccessor: _contextAccessor);
    _view = widget.createView(controller: _controller, viewModel: _viewModel, contextAccessor: _contextAccessor);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _contextAccessor.buildContext = context;
    return _view.body;
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _viewModel.dispose();
    _view.dispose();
  }

}
