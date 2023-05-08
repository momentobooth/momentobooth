import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'manual_collage_screen_view_model.g.dart';

class ManualCollageScreenViewModel = ManualCollageScreenViewModelBase with _$ManualCollageScreenViewModel;

abstract class ManualCollageScreenViewModelBase extends ScreenViewModelBase with Store {

  ManualCollageScreenViewModelBase({
    required super.contextAccessor,
  });

}
