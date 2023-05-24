import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'initialization_screen_view_model.g.dart';

class InitializationScreenViewModel = InitializationScreenViewModelBase with _$InitializationScreenViewModel;

abstract class InitializationScreenViewModelBase extends ScreenViewModelBase with Store {

  InitializationScreenViewModelBase({
    required super.contextAccessor,
  });

}
