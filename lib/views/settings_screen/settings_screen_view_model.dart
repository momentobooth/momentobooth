import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:printing/printing.dart';

part 'settings_screen_view_model.g.dart';

typedef UpdateSettingsCallback = Settings Function(Settings settings);

class SettingsScreenViewModel = SettingsScreenViewModelBase with _$SettingsScreenViewModel;

abstract class SettingsScreenViewModelBase extends ScreenViewModelBase with Store {

  @observable
  int paneIndex = 0;

  PageStorageBucket pageStorageBucket = PageStorageBucket();

  final GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();
  @observable
  int previewTemplate = 1;
  int get previewTemplateRotation => [0, 1, 4].contains(previewTemplate) ? 1 : 0;
  @observable
  bool previewTemplateShowFront = true;
  @observable
  bool previewTemplateShowMiddle = true;
  @observable
  bool previewTemplateShowBack = true;
  String get selectedBackTemplate => collageKey.currentState?.templates[TemplateKind.back]![previewTemplate]?.path ?? "-";
  String get selectedFrontTemplate => collageKey.currentState?.templates[TemplateKind.front]![previewTemplate]?.path ?? "-";

  // Option lists

  List<ComboBoxItem<LiveViewMethod>> get liveViewMethods => LiveViewMethod.asComboBoxItems();
  List<ComboBoxItem<Rotate>> get liveViewAndCaptureRotateOptions => Rotate.asComboBoxItems();
  List<ComboBoxItem<Flip>> get flipOptions => Flip.asComboBoxItems();
  List<ComboBoxItem<CaptureMethod>> get captureMethods => CaptureMethod.asComboBoxItems();
  List<ComboBoxItem<PrintingImplementation>> get printingImplementations => PrintingImplementation.asComboBoxItems();
  List<ComboBoxItem<ExportFormat>> get exportFormats => ExportFormat.asComboBoxItems();
  List<ComboBoxItem<Language>> get languages => Language.asComboBoxItems();
  List<ComboBoxItem<ScreenTransitionAnimation>> get screenTransitionAnimations => ScreenTransitionAnimation.asComboBoxItems();
  List<ComboBoxItem<BackgroundBlur>> get backgroundBlurOptions => BackgroundBlur.asComboBoxItems();
  List<ComboBoxItem<FilterQuality>> get filterQualityOptions => FilterQuality.asComboBoxItems();
  List<ComboBoxItem<GPhoto2SpecialHandling>> get gPhoto2SpecialHandlingOptions => GPhoto2SpecialHandling.asComboBoxItems();
  
  @observable
  ObservableList<ComboBoxItem<String>> flutterPrintingQueues = ObservableList<ComboBoxItem<String>>();

  @observable
  ObservableList<ComboBoxItem<String>> cupsQueues = ObservableList<ComboBoxItem<String>>();

  @observable
  ObservableList<ComboBoxItem<String>> cupsPaperSizes = ObservableList<ComboBoxItem<String>>();

  @observable
  List<ComboBoxItem<String>> webcams = ObservableList<ComboBoxItem<String>>();

  @observable
  List<ComboBoxItem<String>> gPhoto2Cameras = ObservableList<ComboBoxItem<String>>();

  RichText _printerCardText(String printerName, bool isAvailable, bool? isDefault) {
    final icon = isAvailable ? FluentIcons.plug_connected : FluentIcons.plug_disconnected;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF000000)),
        children: [
          TextSpan(text: "$printerName  "),
          if (isDefault == true) ...[
            const WidgetSpan(child: Icon(FluentIcons.default_settings)),
            const TextSpan(text: "  "),
          ],
          WidgetSpan(child: Icon(icon)),
        ],
      ),
    );
  }

  Text _mediaSizeCardText(PrintDimension size) {
    return Text("${size.name} (${size.height.toStringAsFixed(2)}×${size.width.toStringAsFixed(2)} mm)");
  }

  final String unusedPrinterValue = "UNUSED";

  Future<void> setFlutterPrintingQueueList() async {
    final printers = await Printing.listPrinters();

    flutterPrintingQueues
      ..clear()
      ..add(ComboBoxItem(value: unusedPrinterValue, child: _printerCardText("- Not used -", false, false)));

    for (var printer in printers) {
      flutterPrintingQueues.add(ComboBoxItem(value: printer.name, child: _printerCardText(printer.name, printer.isAvailable, printer.isDefault)));
      
      // If there is no setting yet, set it to the default printer.
      if (printer.isDefault && flutterPrintingPrinterNamesSetting.isEmpty) {
        await updateSettings((settings) => settings.copyWith.hardware(flutterPrintingPrinterNames: [printer.name]));
      }
    }
  }

  Future<void> setCupsQueueList() async {
    final List<PrintQueueInfo> printers = await CupsClient().getPrintQueues();

    cupsQueues
      ..clear()
      ..add(ComboBoxItem(value: unusedPrinterValue, child: _printerCardText("- Not used -", false, false)));

    for (var printer in printers) {
      cupsQueues.add(ComboBoxItem(value: printer.id, child: _printerCardText(printer.name, printer.isAvailable, printer.isDefault)));
      
      // If there is no setting yet, set it to the default printer.
      if (cupsPrinterQueuesSetting.isEmpty) {
        await updateSettings((settings) => settings.copyWith.hardware(cupsPrinterQueues: [printer.id]));
      }
    }
  }

  Future<void> setCupsPageSizeOptions() async {
    if (cupsPrinterQueuesSetting.isEmpty) return;
    final List<PrintDimension> mediaDimensions = await CupsClient().getPrinterMediaDimensions(cupsPrinterQueuesSetting.first);

    cupsPaperSizes
      ..clear()
      ..addAll(mediaDimensions.map((media) => ComboBoxItem(value: media.keyword, child: _mediaSizeCardText(media))).toList());
  }
  
  Future<void> setWebcamList() async => webcams = await NokhwaCamera.getCamerasAsComboBoxItems();
  Future<void> setCameraList() async => gPhoto2Cameras = await GPhoto2Camera.getCamerasAsComboBoxItems();

  // Current values

  int get captureDelaySecondsSetting => SettingsManager.instance.settings.captureDelaySeconds;
  double get collageAspectRatioSetting => SettingsManager.instance.settings.collageAspectRatio;
  double get collagePaddingSetting => SettingsManager.instance.settings.collagePadding;
  bool get singlePhotoIsCollageSetting => SettingsManager.instance.settings.singlePhotoIsCollage;
  String get templatesFolderSetting => SettingsManager.instance.settings.templatesFolder;
  Rotate get liveViewAndCaptureRotateSetting => SettingsManager.instance.settings.hardware.liveViewAndCaptureRotate;
  Flip get liveViewFlipSetting => SettingsManager.instance.settings.hardware.liveViewFlip;
  Flip get captureFlipSetting => SettingsManager.instance.settings.hardware.captureFlip;
  double get liveViewAndCaptureAspectRatioSetting => SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio;
  LiveViewMethod get liveViewMethodSetting => SettingsManager.instance.settings.hardware.liveViewMethod;
  String get liveViewWebcamId => SettingsManager.instance.settings.hardware.liveViewWebcamId;
  CaptureMethod get captureMethodSetting => SettingsManager.instance.settings.hardware.captureMethod;
  String get gPhoto2CameraId => SettingsManager.instance.settings.hardware.gPhoto2CameraId;
  GPhoto2SpecialHandling get gPhoto2SpecialHandling => SettingsManager.instance.settings.hardware.gPhoto2SpecialHandling;
  String get gPhoto2CaptureTargetSetting => SettingsManager.instance.settings.hardware.gPhoto2CaptureTarget;
  bool get gPhoto2DownloadExtraFilesSetting => SettingsManager.instance.settings.hardware.gPhoto2DownloadExtraFiles;
  int get gPhoto2AutoFocusMsBeforeCaptureSetting => SettingsManager.instance.settings.hardware.gPhoto2AutoFocusMsBeforeCapture;
  int get captureDelayGPhoto2Setting => SettingsManager.instance.settings.hardware.captureDelayGPhoto2;
  int get captureDelaySonySetting => SettingsManager.instance.settings.hardware.captureDelaySony;
  String get captureLocationSetting => SettingsManager.instance.settings.hardware.captureLocation;
  bool get saveCapturesToDiskSetting => SettingsManager.instance.settings.hardware.saveCapturesToDisk;
  String get captureStorageLocationSetting => SettingsManager.instance.settings.hardware.captureStorageLocation;
  PrintingImplementation get printingImplementationSetting => SettingsManager.instance.settings.hardware.printingImplementation;
  String get cupsUriSetting => SettingsManager.instance.settings.hardware.cupsUri;
  bool get cupsIgnoreTlsErrors => SettingsManager.instance.settings.hardware.cupsIgnoreTlsErrors;
  String get cupsUsernameSetting => SettingsManager.instance.settings.hardware.cupsUsername;
  String get cupsPasswordSetting => SettingsManager.instance.settings.hardware.cupsPassword;
  List<String> get cupsPrinterQueuesSetting => SettingsManager.instance.settings.hardware.cupsPrinterQueues;
  MediaSettings get mediaSizeNormal => SettingsManager.instance.settings.hardware.printLayoutSettings.mediaSizeNormal;
  MediaSettings get mediaSizeSplit => SettingsManager.instance.settings.hardware.printLayoutSettings.mediaSizeSplit;
  MediaSettings get mediaSizeSmall => SettingsManager.instance.settings.hardware.printLayoutSettings.mediaSizeSmall;
  int get gridXSmall => SettingsManager.instance.settings.hardware.printLayoutSettings.gridXSmall;
  int get gridYSmall => SettingsManager.instance.settings.hardware.printLayoutSettings.gridYSmall;
  bool get rotateSmall => SettingsManager.instance.settings.hardware.printLayoutSettings.rotateSmall;
  MediaSettings get mediaSizeTiny => SettingsManager.instance.settings.hardware.printLayoutSettings.mediaSizeTiny;
  int get gridXTiny => SettingsManager.instance.settings.hardware.printLayoutSettings.gridXTiny;
  int get gridYTiny => SettingsManager.instance.settings.hardware.printLayoutSettings.gridYTiny;
  bool get rotateTiny => SettingsManager.instance.settings.hardware.printLayoutSettings.rotateTiny;
  List<String> get flutterPrintingPrinterNamesSetting => SettingsManager.instance.settings.hardware.flutterPrintingPrinterNames;
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
  Color get primaryColorSetting => SettingsManager.instance.settings.ui.primaryColor;
  int get returnToHomeTimeoutSeconds => SettingsManager.instance.settings.ui.returnToHomeTimeoutSeconds;
  bool get displayConfettiSetting => SettingsManager.instance.settings.ui.displayConfetti;
  bool get customColorConfettiSetting => SettingsManager.instance.settings.ui.customColorConfetti;
  bool get enableSfxSetting => SettingsManager.instance.settings.ui.enableSfx;
  String get clickSfxFileSetting => SettingsManager.instance.settings.ui.clickSfxFile;
  String get shareScreenSfxFileSetting => SettingsManager.instance.settings.ui.shareScreenSfxFile;
  Language get languageSetting => SettingsManager.instance.settings.ui.language;
  bool get allowScrollGestureWithMouse => SettingsManager.instance.settings.ui.allowScrollGestureWithMouse;
  ScreenTransitionAnimation get screenTransitionAnimation => SettingsManager.instance.settings.ui.screenTransitionAnimation;
  BackgroundBlur get backgroundBlur => SettingsManager.instance.settings.ui.backgroundBlur;
  FilterQuality get screenTransitionAnimationFilterQuality => SettingsManager.instance.settings.ui.screenTransitionAnimationFilterQuality;
  FilterQuality get liveViewFilterQuality => SettingsManager.instance.settings.ui.liveViewFilterQuality;
  bool get mqttIntegrationEnableSetting => SettingsManager.instance.settings.mqttIntegration.enable;
  String get mqttIntegrationHostSetting => SettingsManager.instance.settings.mqttIntegration.host;
  int get mqttIntegrationPortSetting => SettingsManager.instance.settings.mqttIntegration.port;
  bool get mqttIntegrationSecureSetting => SettingsManager.instance.settings.mqttIntegration.secure;
  bool get mqttIntegrationVerifyCertificateSetting => SettingsManager.instance.settings.mqttIntegration.verifyCertificate;
  bool get mqttIntegrationUseWebSocketSetting => SettingsManager.instance.settings.mqttIntegration.useWebSocket;
  String get mqttIntegrationUsernameSetting => SettingsManager.instance.settings.mqttIntegration.username;
  String get mqttIntegrationClientIdSetting => SettingsManager.instance.settings.mqttIntegration.clientId;
  String get mqttIntegrationRootTopicSetting => SettingsManager.instance.settings.mqttIntegration.rootTopic;
  bool get mqttIntegrationEnableHomeAssistantDiscoverySetting => SettingsManager.instance.settings.mqttIntegration.enableHomeAssistantDiscovery;
  String get mqttIntegrationHomeAssistantDiscoveryTopicPrefixSetting => SettingsManager.instance.settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
  String get mqttIntegrationHomeAssistantComponentIdSetting => SettingsManager.instance.settings.mqttIntegration.homeAssistantComponentId;
  bool get faceRecognitionEnabled => SettingsManager.instance.settings.faceRecognition.enable;
  String get faceRecognitionServerUrlSetting => SettingsManager.instance.settings.faceRecognition.serverUrl;
  bool get debugShowFpsCounter => SettingsManager.instance.settings.debug.showFpsCounter;

  double get outputResHeightExcl => resolutionMultiplier * 1000;
  double get outputResWidthExcl => outputResHeightExcl/collageAspectRatioSetting;
  double get outputResHeightIncl => outputResHeightExcl + collagePaddingSetting * 2 * resolutionMultiplier;
  double get outputResWidthIncl => outputResWidthExcl + collagePaddingSetting * 2 * resolutionMultiplier;

  // Initializers/Deinitializers

  SettingsScreenViewModelBase({
    required super.contextAccessor,
  }) {
    setFlutterPrintingQueueList();
    setWebcamList();
    setCameraList();
    setCupsPageSizeOptions();
  }

  // Methods

  Future<void> updateSettings(UpdateSettingsCallback updateCallback) async {
    Settings currentSettings = SettingsManager.instance.settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await SettingsManager.instance.updateAndSave(updatedSettings);
  }

}
