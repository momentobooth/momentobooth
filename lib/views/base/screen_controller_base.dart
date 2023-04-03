import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_abstractor.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:meta/meta.dart';

abstract class ScreenControllerBase<T extends ScreenViewModelBase> with BuildContextAbstractor {

  final T viewModel;

  @override
  final BuildContextAccessor contextAccessor;

  ScreenControllerBase({
    required this.viewModel,
    required this.contextAccessor,
  });

  @mustCallSuper
  void dispose() {
  }

}
