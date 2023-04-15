import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/models/hardware/live_view_streaming/nokhwa_camera.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';
import 'package:printing/printing.dart';

part 'settings_screen_view_model.g.dart';

typedef UpdateSettingsCallback = Settings Function(Settings settings);

class SettingsScreenViewModel = SettingsScreenViewModelBase with _$SettingsScreenViewModel;

abstract class SettingsScreenViewModelBase extends ScreenViewModelBase with Store {

  @observable
  int paneIndex = 0;

  // Option lists

  List<ComboBoxItem<LiveViewMethod>> get liveViewMethods => LiveViewMethod.asComboBoxItems();
  List<ComboBoxItem<CaptureMethod>> get captureMethods => CaptureMethod.asComboBoxItems();
  List<ComboBoxItem<ExportFormat>> get exportFormats => ExportFormat.asComboBoxItems();
  
  @observable
  ObservableList<ComboBoxItem<String>> printerOptions = ObservableList<ComboBoxItem<String>>();

  @observable
  List<ComboBoxItem<String>> webcams = ObservableList<ComboBoxItem<String>>();

  void setPrinterList() async {
    final printers = await Printing.listPrinters();
    print("Getting printers:");
    print(printers);
    printerOptions.clear();
    for (var printer in printers) {
      final icon = printer.isAvailable ? FluentIcons.plug_connected : FluentIcons.plug_disconnected;
      final text = RichText(
        text: TextSpan(
          style: TextStyle(color: Color(0xFF000000)),
          children: [
            TextSpan(text: "${printer.name}  "),
            if (printer.isDefault) ...[
              WidgetSpan(child: Icon(FluentIcons.default_settings)),
              TextSpan(text: "  "),
            ],
            WidgetSpan(child: Icon(icon)),
          ],
        ),
      );
      printerOptions.add(ComboBoxItem(value: printer.name, child: text));
      
      // If there is no setting yet, set it to the default printer.
      if (printer.isDefault && printerSetting == "") {
        updateSettings((settings) => settings.copyWith.hardware(printerName: printer.name));
      }
    }
  }
  
  void setWebcamList() async => webcams = await NokhwaCamera.asComboBoxItems();

  // Current values

  int get captureDelaySecondsSetting => SettingsManagerBase.instance.settings.captureDelaySeconds;
  LiveViewMethod get liveViewMethodSetting => SettingsManagerBase.instance.settings.hardware.liveViewMethod;
  String get liveViewWebcamId => SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;
  CaptureMethod get captureMethodSetting => SettingsManagerBase.instance.settings.hardware.captureMethod;
  String get captureLocationSetting => SettingsManagerBase.instance.settings.hardware.captureLocation;
  String get printerSetting => SettingsManagerBase.instance.settings.hardware.printerName;
  String get localFolderSetting => SettingsManagerBase.instance.settings.output.localFolder;
  String get firefoxSendServerUrlSetting => SettingsManagerBase.instance.settings.output.firefoxSendServerUrl;
  ExportFormat get exportFormat => SettingsManagerBase.instance.settings.output.exportFormat;
  int get jpgQuality => SettingsManagerBase.instance.settings.output.jpgQuality;
  double get resolutionMultiplier => SettingsManagerBase.instance.settings.output.resolutionMultiplier;

  // Initializers/Deinitializers

  SettingsScreenViewModelBase({
    required super.contextAccessor,
  }) {
    setPrinterList();
    setWebcamList();
  }

  // Methods

  Future<void> updateSettings(UpdateSettingsCallback updateCallback) async {
    Settings currentSettings = SettingsManagerBase.instance.settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await SettingsManagerBase.instance.updateAndSave(updatedSettings);
  }

}
