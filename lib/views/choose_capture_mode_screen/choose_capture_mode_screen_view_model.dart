import 'package:auto_size_text/auto_size_text.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'choose_capture_mode_screen_view_model.g.dart';

class ChooseCaptureModeScreenViewModel = ChooseCaptureModeScreenViewModelBase with _$ChooseCaptureModeScreenViewModel;

abstract class ChooseCaptureModeScreenViewModelBase extends ScreenViewModelBase with Store {

  AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  ChooseCaptureModeScreenViewModelBase({
    required super.contextAccessor,
  });

}
