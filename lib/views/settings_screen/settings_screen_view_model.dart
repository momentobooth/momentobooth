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
  List<ComboBoxItem<FilterQuality>> get filterQualityOptions => FilterQuality.asComboBoxItems();
  
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

  int get captureDelaySecondsSetting => SettingsManager.instance.settings.captureDelaySeconds;
  bool get displayConfettiSetting => SettingsManager.instance.settings.displayConfetti;
  double get collageAspectRatioSetting => SettingsManager.instance.settings.collageAspectRatio;
  double get collagePaddingSetting => SettingsManager.instance.settings.collagePadding;
  bool get singlePhotoIsCollageSetting => SettingsManager.instance.settings.singlePhotoIsCollage;
  String get templatesFolderSetting => SettingsManager.instance.settings.templatesFolder;
  LiveViewMethod get liveViewMethodSetting => SettingsManager.instance.settings.hardware.liveViewMethod;
  String get liveViewWebcamId => SettingsManager.instance.settings.hardware.liveViewWebcamId;
  Flip get liveViewFlipImage => SettingsManager.instance.settings.hardware.liveViewFlipImage;
  CaptureMethod get captureMethodSetting => SettingsManager.instance.settings.hardware.captureMethod;
  int get captureDelaySonySetting => SettingsManager.instance.settings.hardware.captureDelaySony;
  String get captureLocationSetting => SettingsManager.instance.settings.hardware.captureLocation;
  List<String> get printersSetting => SettingsManager.instance.settings.hardware.printerNames;
  double get pageHeightSetting => SettingsManager.instance.settings.hardware.pageHeight;
  double get pageWidthSetting => SettingsManager.instance.settings.hardware.pageWidth;
  bool get usePrinterSettingsSetting => SettingsManager.instance.settings.hardware.usePrinterSettings;
  double get printerMarginTopSetting => SettingsManager.instance.settings.hardware.printerMarginTop;
  double get printerMarginRightSetting => SettingsManager.instance.settings.hardware.printerMarginRight;
  double get printerMarginBottomSetting => SettingsManager.instance.settings.hardware.printerMarginBottom;
  double get printerMarginLeftSetting => SettingsManager.instance.settings.hardware.printerMarginLeft;
  int get printerQueueWarningThresholdSetting => SettingsManager.instance.settings.hardware.printerQueueWarningThreshold;
  String get localFolderSetting => SettingsManager.instance.settings.output.localFolder;
  String get firefoxSendServerUrlSetting => SettingsManager.instance.settings.output.firefoxSendServerUrl;
  ExportFormat get exportFormat => SettingsManager.instance.settings.output.exportFormat;
  int get jpgQuality => SettingsManager.instance.settings.output.jpgQuality;
  double get resolutionMultiplier => SettingsManager.instance.settings.output.resolutionMultiplier;
  FilterQuality get screenTransitionAnimationFilterQuality => SettingsManager.instance.settings.debug.screenTransitionAnimationFilterQuality;
  FilterQuality get liveViewFilterQuality => SettingsManager.instance.settings.debug.liveViewFilterQuality;

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
    Settings currentSettings = SettingsManager.instance.settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await SettingsManager.instance.updateAndSave(updatedSettings);
  }

}
