import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'navigation_screen_view_model.g.dart';

class NavigationScreenViewModel = NavigationScreenViewModelBase with _$NavigationScreenViewModel;

abstract class NavigationScreenViewModelBase extends ScreenViewModelBase with Store {

  NavigationScreenViewModelBase({
    required super.contextAccessor,
  });

  
  bool get enableSingleCapture => getIt<ProjectManager>().settings.enableSingleCapture;
  bool get enableCollageCapture => getIt<ProjectManager>().settings.enableCollageCapture;

}
