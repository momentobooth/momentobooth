import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'settings_screen_view_model.g.dart';

typedef UpdateSettingsCallback = Settings Function(Settings settings);

class SettingsScreenViewModel = SettingsScreenViewModelBase with _$SettingsScreenViewModel;

abstract class SettingsScreenViewModelBase extends ScreenViewModelBase with Store {

  @observable
  int paneIndex = 0;

  // Option lists

  List<ComboBoxItem<LiveViewMethod>> get liveViewMethods => LiveViewMethod.asComboBoxItems();
  List<ComboBoxItem<CaptureMethod>> get captureMethods => CaptureMethod.asComboBoxItems();

  // Current values

  int get captureDelaySecondsSetting => SettingsManagerBase.instance.settings.captureDelaySeconds;
  LiveViewMethod get liveViewMethodSetting => SettingsManagerBase.instance.settings.hardware.liveViewMethod;
  CaptureMethod get captureMethodSetting => SettingsManagerBase.instance.settings.hardware.captureMethod;
  String get captureLocationSetting => SettingsManagerBase.instance.settings.hardware.captureLocation;
  String get localFolderSetting => SettingsManagerBase.instance.settings.output.localFolder;
  String get firefoxSendServerUrlSetting => SettingsManagerBase.instance.settings.output.firefoxSendServerUrl;

  // Initializers/Deinitializers

  SettingsScreenViewModelBase({
    required super.contextAccessor,
  });

  // Methods

  Future<void> updateSettings(UpdateSettingsCallback updateCallback) async {
    Settings currentSettings = SettingsManagerBase.instance.settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await SettingsManagerBase.instance.updateAndSave(updatedSettings);
  }

}
