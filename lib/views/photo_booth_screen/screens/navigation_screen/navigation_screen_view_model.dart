import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'navigation_screen_view_model.g.dart';

class NavigationScreenViewModel = NavigationScreenViewModelBase with _$NavigationScreenViewModel;

abstract class NavigationScreenViewModelBase extends ScreenViewModelBase with Store {

  NavigationScreenViewModelBase({
    required super.contextAccessor,
  });

}
