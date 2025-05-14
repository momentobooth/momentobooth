import 'package:mobx/mobx.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'choose_capture_mode_screen_view_model.g.dart';

class ChooseCaptureModeScreenViewModel = ChooseCaptureModeScreenViewModelBase with _$ChooseCaptureModeScreenViewModel;

abstract class ChooseCaptureModeScreenViewModelBase extends ScreenViewModelBase with Store {

  ChooseCaptureModeScreenViewModelBase({
    required super.contextAccessor,
  });

}
