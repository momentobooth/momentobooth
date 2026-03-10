import 'package:meta/meta.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/base/build_context_abstractor.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

abstract class ScreenControllerBase<T extends ScreenViewModelBase> with BuildContextAbstractor, Logger {

  final T viewModel;

  @override
  final BuildContextAccessor contextAccessor;

  ScreenControllerBase({
    required this.viewModel,
    required this.contextAccessor,
  }) {
    getIt<ActionManager>().push(actions, _actionStackToken);
  }

  @mustCallSuper
  void dispose() {
    getIt<ActionManager>().pop(_actionStackToken);
  }

  final Object _actionStackToken = Object();
  List<AppAction> get actions => [];

}
