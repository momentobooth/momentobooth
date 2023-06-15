import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'collage_maker_screen_view_model.g.dart';

class CollageMakerScreenViewModel = CollageMakerScreenViewModelBase with _$CollageMakerScreenViewModel;

abstract class CollageMakerScreenViewModelBase extends ScreenViewModelBase with Store {

  CollageMakerScreenViewModelBase({
    required super.contextAccessor,
  });

  int get numSelected => PhotosManager.instance.chosen.length;
  
  double get collageAspectRatio => SettingsManager.instance.settings.collageAspectRatio;
  double get collagePadding => SettingsManager.instance.settings.collagePadding;

  int get rotation => [0, 1, 4].contains(numSelected) ? 1 : 0;
  
  @observable
  bool readyToContinue = false;

  final Duration opacityDuraction = const Duration(milliseconds: 300);

}
