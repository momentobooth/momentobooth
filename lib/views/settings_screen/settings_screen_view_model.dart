import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'settings_screen_view_model.g.dart';

class SettingsScreenViewModel = SettingsScreenViewModelBase with _$SettingsScreenViewModel;

abstract class SettingsScreenViewModelBase extends ScreenViewModelBase with Store {

  @observable
  int paneIndex = 0;

  SettingsScreenViewModelBase({
    required super.contextAccessor,
  });

}
