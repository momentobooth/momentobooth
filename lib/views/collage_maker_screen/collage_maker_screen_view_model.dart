import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'collage_maker_screen_view_model.g.dart';

class CollageMakerScreenViewModel = CollageMakerScreenViewModelBase with _$CollageMakerScreenViewModel;

abstract class CollageMakerScreenViewModelBase extends ScreenViewModelBase with Store {

  CollageMakerScreenViewModelBase({
    required super.contextAccessor,
  });

  @observable
  int rotation = 0;

}
