import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
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
  List<ComboBoxItem<Flip>> get liveViewFlipImageChoices => Flip.asComboBoxItems();
  List<ComboBoxItem<CaptureMethod>> get captureMethods => CaptureMethod.asComboBoxItems();
  List<ComboBoxItem<ExportFormat>> get exportFormats => ExportFormat.asComboBoxItems();
  
  @observable
  ObservableList<ComboBoxItem<String>> printerOptions = ObservableList<ComboBoxItem<String>>();

  @observable
  List<ComboBoxItem<String>> webcams = ObservableList<ComboBoxItem<String>>();

  RichText _printerCardText(String printerName, bool isAvailable, bool isDefault) {
    final icon = isAvailable ? FluentIcons.plug_connected : FluentIcons.plug_disconnected;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF000000)),
        children: [
          TextSpan(text: "$printerName  "),
          if (isDefault) ...[
            const WidgetSpan(child: Icon(FluentIcons.default_settings)),
            const TextSpan(text: "  "),
          ],
          WidgetSpan(child: Icon(icon)),
        ],
      ),
    );
  }

  final String unsedPrinterValue = "UNUSED";

  void setPrinterList() async {
    final printers = await Printing.listPrinters();
    printerOptions.clear();
    printerOptions.add(ComboBoxItem(value: unsedPrinterValue, child: _printerCardText("- Not used -", false, false)));
    for (var printer in printers) {
      printerOptions.add(ComboBoxItem(value: printer.name, child: _printerCardText(printer.name, printer.isAvailable, printer.isDefault)));
      
      // If there is no setting yet, set it to the default printer.
      if (printer.isDefault && printersSetting.isEmpty) {
        updateSettings((settings) => settings.copyWith.hardware(printerNames: [printer.name]));
      }
    }
  }
  
  void setWebcamList() async => webcams = await NokhwaCamera.getCamerasAsComboBoxItems();

  // Current values

  int get captureDelaySecondsSetting => SettingsManagerBase.instance.settings.captureDelaySeconds;
  bool get displayConfettiSetting => SettingsManagerBase.instance.settings.displayConfetti;
  double get collageAspectRatioSetting => SettingsManagerBase.instance.settings.collageAspectRatio;
  double get collagePaddingSetting => SettingsManagerBase.instance.settings.collagePadding;
  bool get singlePhotoIsCollageSetting => SettingsManagerBase.instance.settings.singlePhotoIsCollage;
  String get templatesFolderSetting => SettingsManagerBase.instance.settings.templatesFolder;
  LiveViewMethod get liveViewMethodSetting => SettingsManagerBase.instance.settings.hardware.liveViewMethod;
  String get liveViewWebcamId => SettingsManagerBase.instance.settings.hardware.liveViewWebcamId;
  Flip get liveViewFlipImage => SettingsManagerBase.instance.settings.hardware.liveViewFlipImage;
  CaptureMethod get captureMethodSetting => SettingsManagerBase.instance.settings.hardware.captureMethod;
  int get captureDelaySonySetting => SettingsManagerBase.instance.settings.hardware.captureDelaySony;
  String get captureLocationSetting => SettingsManagerBase.instance.settings.hardware.captureLocation;
  List<String> get printersSetting => SettingsManagerBase.instance.settings.hardware.printerNames;
  double get pageHeightSetting => SettingsManagerBase.instance.settings.hardware.pageHeight;
  double get pageWidthSetting => SettingsManagerBase.instance.settings.hardware.pageWidth;
  bool get usePrinterSettingsSetting => SettingsManagerBase.instance.settings.hardware.usePrinterSettings;
  double get printerMarginTopSetting => SettingsManagerBase.instance.settings.hardware.printerMarginTop;
  double get printerMarginRightSetting => SettingsManagerBase.instance.settings.hardware.printerMarginRight;
  double get printerMarginBottomSetting => SettingsManagerBase.instance.settings.hardware.printerMarginBottom;
  double get printerMarginLeftSetting => SettingsManagerBase.instance.settings.hardware.printerMarginLeft;
  String get localFolderSetting => SettingsManagerBase.instance.settings.output.localFolder;
  String get firefoxSendServerUrlSetting => SettingsManagerBase.instance.settings.output.firefoxSendServerUrl;
  ExportFormat get exportFormat => SettingsManagerBase.instance.settings.output.exportFormat;
  int get jpgQuality => SettingsManagerBase.instance.settings.output.jpgQuality;
  double get resolutionMultiplier => SettingsManagerBase.instance.settings.output.resolutionMultiplier;

  double get outputResHeightExcl => resolutionMultiplier * 1000;
  double get outputResWidthExcl => outputResHeightExcl/collageAspectRatioSetting;
  double get outputResHeightIncl => outputResHeightExcl + collagePaddingSetting * 2 * resolutionMultiplier;
  double get outputResWidthIncl => outputResWidthExcl + collagePaddingSetting * 2 * resolutionMultiplier;

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
