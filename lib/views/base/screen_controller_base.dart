import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';

abstract class ScreenControllerBase<T extends ScreenViewModelBase> {

  final T viewModel;

  const ScreenControllerBase({required this.viewModel});

}
