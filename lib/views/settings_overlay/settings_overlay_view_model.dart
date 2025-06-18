import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/gphoto2_camera.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/external_system_status_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/gphoto2.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/nokhwa.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/utils/color_vision_deficiency.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:printing/printing.dart';

part 'settings_overlay_view_model.g.dart';

typedef UpdateSettingsCallback = Settings Function(Settings settings);
typedef UpdateProjectSettingsCallback = ProjectSettings Function(ProjectSettings settings);

class SettingsOverlayViewModel = SettingsOverlayViewModelBase with _$SettingsOverlayViewModel;

abstract class SettingsOverlayViewModelBase extends ScreenViewModelBase with Store {

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

  List<ComboBoxItem<CollageMode>> get collageModeOptions => CollageMode.asComboBoxItems();
  List<ComboBoxItem<LiveViewMethod>> get liveViewMethods => LiveViewMethod.asComboBoxItems();
  List<ComboBoxItem<Rotate>> get liveViewAndCaptureRotateOptions => Rotate.asComboBoxItems();
  List<ComboBoxItem<Flip>> get flipOptions => Flip.asComboBoxItems();
  List<ComboBoxItem<CaptureMethod>> get captureMethods => CaptureMethod.asComboBoxItems();
  List<ComboBoxItem<PrintingImplementation>> get printingImplementations => PrintingImplementation.asComboBoxItems();
  List<ComboBoxItem<ExportFormat>> get exportFormats => ExportFormat.asComboBoxItems();
  List<ComboBoxItem<Language>> get languages => Language.asComboBoxItems();
  List<ComboBoxItem<Language>> get languagesProject => Language.asOptionalComboBoxItems();
  List<ComboBoxItem<ScreenTransitionAnimation>> get screenTransitionAnimations => ScreenTransitionAnimation.asComboBoxItems();
  List<ComboBoxItem<BackgroundBlur>> get backgroundBlurOptions => BackgroundBlur.asComboBoxItems();
  List<ComboBoxItem<FilterQuality>> get filterQualityOptions => FilterQuality.asComboBoxItems();
  List<ComboBoxItem<GPhoto2SpecialHandling>> get gPhoto2SpecialHandlingOptions => GPhoto2SpecialHandling.asComboBoxItems();
  List<ComboBoxItem<UiTheme>> get uiThemeOptions => UiTheme.asComboBoxItems();

  @observable
  List<ComboBoxItem<String>> flutterPrintingQueues = List<ComboBoxItem<String>>.empty();

  @observable
  List<ComboBoxItem<String>> cupsQueues = List<ComboBoxItem<String>>.empty();

  @observable
  List<ComboBoxItem<String>> cupsPaperSizes = List<ComboBoxItem<String>>.empty();

  @observable
  List<ComboBoxItem<String>> webcamComboBoxItems = List<ComboBoxItem<String>>.empty();

  @observable
  List<NokhwaCameraInfo> webcamList = List<NokhwaCameraInfo>.empty();

  @observable
  List<ComboBoxItem<String>> gPhoto2CameraComboBoxItems = List<ComboBoxItem<String>>.empty();

  @observable
  List<GPhoto2CameraInfo> gPhoto2CameraList = List<GPhoto2CameraInfo>.empty();

  SubsystemStatus get badgeStatus {
    final subsystemList = getIt<ObservableList<Subsystem>>().map((s) => s.subsystemStatus).toList();
    final externalSystemList = getIt<ExternalSystemStatusManager>().systemStatuses;
    final checkList = subsystemList + externalSystemList;

    if (checkList.any((s) => s is SubsystemStatusError)) {
      return const SubsystemStatus.error(message: '');
    } else if (checkList.any((s) => s is SubsystemStatusWarning)) {
      return const SubsystemStatus.warning(message: '');
    } else if (checkList.any((s) => s is SubsystemStatusBusy)) {
      return const SubsystemStatus.busy(message: '');
    } else {
      return const SubsystemStatus.ok();
    }
  }

  RichText _printerCardText(String printerName, bool isAvailable, bool? isDefault) {
    final icon = isAvailable ? LucideIcons.plug : LucideIcons.unplug;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF000000)),
        children: [
          TextSpan(text: "$printerName  "),
          if (isDefault == true) ...[
            const WidgetSpan(child: Icon(LucideIcons.printerCheck)),
            const TextSpan(text: "  "),
          ],
          WidgetSpan(child: Icon(icon)),
        ],
      ),
    );
  }

  Text _mediaSizeCardText(PrintDimension size) {
    return Text("${size.name} (${size.height.toStringAsFixed(2)}↕ × ${size.width.toStringAsFixed(2)}↔ mm)");
  }

  final String unusedPrinterValue = "UNUSED";

  Future<void> setFlutterPrintingQueueList() async {
    final printers = await Printing.listPrinters();

    flutterPrintingQueues = [
      ComboBoxItem(value: unusedPrinterValue, child: _printerCardText("- Not used -", false, false)),
      ...printers.map((p) => ComboBoxItem(value: p.name, child: _printerCardText(p.name, p.isAvailable, p.isDefault))),
    ];

    // If there is no printer selected yet, set the OS's default printer as our first printer.
    Printer? osDefaultPrinter = printers.firstWhereOrNull((p) => p.isDefault);
    if (osDefaultPrinter != null && flutterPrintingPrinterNamesSetting.isEmpty) {
      await updateSettings((settings) => settings.copyWith.hardware(flutterPrintingPrinterNames: [osDefaultPrinter.name]));
    }
  }

  Future<void> setCupsQueueList() async {
    final List<PrintQueueInfo> printers = await CupsClient().getPrintQueues();

    cupsQueues = [
      ComboBoxItem(value: unusedPrinterValue, child: _printerCardText("- Not used -", false, false)),
      ...printers.map((p) => ComboBoxItem(value: p.id, child: _printerCardText(p.name, p.isAvailable, p.isDefault))),
    ];

    // If there is no printer selected yet, set the first found printer as our first printer.
    if (printers.isNotEmpty && cupsPrinterQueuesSetting.isEmpty) {
      await updateSettings((settings) => settings.copyWith.hardware(cupsPrinterQueues: [printers.first.id]));
    }
  }

  List<PrintDimension> _mediaDimensions = [];
  List<PrintDimension> get mediaDimensions => _mediaDimensions;

  Future<void> setCupsPageSizeOptions() async {
    if (cupsPrinterQueuesSetting.isEmpty) return;
    _mediaDimensions = await CupsClient().getPrinterMediaDimensions(cupsPrinterQueuesSetting.first);

    cupsPaperSizes = [
      const ComboBoxItem(value: "", child: Text("- Not used -")),
      ..._mediaDimensions.map((m) => ComboBoxItem(value: m.keyword, child: _mediaSizeCardText(m))),
    ];
  }

  Future<void> setImagingDeviceList() async {
    unawaited(setWebcamList2());
    unawaited(setCameraList2());
  }
  Future<void> setWebcamList() async => webcamComboBoxItems = await NokhwaCamera.getCamerasAsComboBoxItems();
  Future<void> setWebcamList2() async => webcamList = await NokhwaCamera.listCameras();
  Future<void> setCameraList() async => gPhoto2CameraComboBoxItems = await GPhoto2Camera.getCamerasAsComboBoxItems();
  Future<void> setCameraList2() async => gPhoto2CameraList = await GPhoto2Camera.listCameras();

  @computed
  ImagingMethod get imagingMethod {
    if (showCustomImagingSettings) {
      return ImagingMethod.custom;
    }
    if (captureMethodSetting == CaptureMethod.liveViewSource) {
      return switch (liveViewMethodSetting) {
        LiveViewMethod.debugNoise => ImagingMethod.debugNoise,
        LiveViewMethod.webcam => ImagingMethod.webcam,
        LiveViewMethod.debugStaticImage => ImagingMethod.debugStaticImage,
        LiveViewMethod.serveFromDirectory => ImagingMethod.debugServeFromDirectory,
        _ => ImagingMethod.custom
      };
    } else if (liveViewMethodSetting == LiveViewMethod.gphoto2 && captureMethodSetting == CaptureMethod.gPhoto2) {
      return ImagingMethod.gphoto2;
    } else {
      return ImagingMethod.custom;
    }
  }

  @observable
  bool showCustomImagingSettings = false;

  // Project settings current values
  UiTheme get uiTheme => getIt<ProjectManager>().settings.uiTheme;
  String get introScreenTouchToStartOverrideTextSetting => getIt<ProjectManager>().settings.introScreenTouchToStartOverrideText;
  bool get displayConfettiSetting => getIt<ProjectManager>().settings.displayConfetti;
  bool get customColorConfettiSetting => getIt<ProjectManager>().settings.customColorConfetti;
  bool get enableSingleCaptureSetting => getIt<ProjectManager>().settings.enableSingleCapture;
  bool get singlePhotoIsCollageSetting => getIt<ProjectManager>().settings.singlePhotoIsCollage;
  bool get enableCollageCaptureSetting => getIt<ProjectManager>().settings.enableCollageCapture;
  CollageMode get collageModeSetting => getIt<ProjectManager>().settings.collageMode;
  Color get primaryColorSetting => getIt<ProjectManager>().settings.primaryColor;
  Language get projectLanguageSetting => getIt<ProjectManager>().settings.language;
  List<Language> get projectAvailableLanguagesSetting => getIt<ProjectManager>().settings.availableLanguages;

  // System settings current values
  int get captureDelaySecondsSetting => getIt<SettingsManager>().settings.captureDelaySeconds;
  bool get loadLastProjectSetting => getIt<SettingsManager>().settings.loadLastProject;
  double get collageAspectRatioSetting => getIt<SettingsManager>().settings.collageAspectRatio;
  double get collagePaddingSetting => getIt<SettingsManager>().settings.collagePadding;
  bool get enableWakelockSetting => getIt<SettingsManager>().settings.enableWakelock;
  Rotate get liveViewAndCaptureRotateSetting => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate;
  Flip get liveViewFlipSetting => getIt<SettingsManager>().settings.hardware.liveViewFlip;
  Flip get captureFlipSetting => getIt<SettingsManager>().settings.hardware.captureFlip;
  double get liveViewAndCaptureAspectRatioSetting => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;
  LiveViewMethod get liveViewMethodSetting => getIt<SettingsManager>().settings.hardware.liveViewMethod;
  String get liveViewWebcamId => getIt<SettingsManager>().settings.hardware.liveViewWebcamId;
  CaptureMethod get captureMethodSetting => getIt<SettingsManager>().settings.hardware.captureMethod;
  String get gPhoto2CameraId => getIt<SettingsManager>().settings.hardware.gPhoto2CameraId;
  GPhoto2SpecialHandling get gPhoto2SpecialHandling => getIt<SettingsManager>().settings.hardware.gPhoto2SpecialHandling;
  String get gPhoto2CaptureTargetSetting => getIt<SettingsManager>().settings.hardware.gPhoto2CaptureTarget;
  bool get gPhoto2DownloadExtraFilesSetting => getIt<SettingsManager>().settings.hardware.gPhoto2DownloadExtraFiles;
  int get gPhoto2AutoFocusMsBeforeCaptureSetting => getIt<SettingsManager>().settings.hardware.gPhoto2AutoFocusMsBeforeCapture;
  int get captureDelayGPhoto2Setting => getIt<SettingsManager>().settings.hardware.captureDelayGPhoto2;
  int get captureDelaySonySetting => getIt<SettingsManager>().settings.hardware.captureDelaySony;
  String get captureLocationSetting => getIt<SettingsManager>().settings.hardware.captureLocation;
  String get serveFromDirectoryPathSetting => getIt<SettingsManager>().settings.hardware.serveFromDirectoryPath;
  bool get saveCapturesToDiskSetting => getIt<SettingsManager>().settings.hardware.saveCapturesToDisk;
  PrintingImplementation get printingImplementationSetting => getIt<SettingsManager>().settings.hardware.printingImplementation;
  String get cupsUriSetting => getIt<SettingsManager>().settings.hardware.cupsUri;
  bool get cupsIgnoreTlsErrors => getIt<SettingsManager>().settings.hardware.cupsIgnoreTlsErrors;
  String get cupsUsernameSetting => getIt<SettingsManager>().settings.hardware.cupsUsername;
  String get cupsPasswordSetting => getIt<SettingsManager>().settings.hardware.cupsPassword;
  List<String> get cupsPrinterQueuesSetting => getIt<SettingsManager>().settings.hardware.cupsPrinterQueues;
  MediaSettings get mediaSizeNormal => getIt<SettingsManager>().settings.hardware.printLayoutSettings.mediaSizeNormal;
  MediaSettings get mediaSizeSplit => getIt<SettingsManager>().settings.hardware.printLayoutSettings.mediaSizeSplit;
  MediaSettings get mediaSizeSmall => getIt<SettingsManager>().settings.hardware.printLayoutSettings.mediaSizeSmall;
  GridSettings get gridSmall => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridSmall;
  MediaSettings get mediaSizeTiny => getIt<SettingsManager>().settings.hardware.printLayoutSettings.mediaSizeTiny;
  GridSettings get gridTiny => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridTiny;
  List<String> get flutterPrintingPrinterNamesSetting => getIt<SettingsManager>().settings.hardware.flutterPrintingPrinterNames;
  double get pageHeightSetting => getIt<SettingsManager>().settings.hardware.pageHeight;
  double get pageWidthSetting => getIt<SettingsManager>().settings.hardware.pageWidth;
  bool get usePrinterSettingsSetting => getIt<SettingsManager>().settings.hardware.usePrinterSettings;
  double get printerMarginTopSetting => getIt<SettingsManager>().settings.hardware.printerMarginTop;
  double get printerMarginRightSetting => getIt<SettingsManager>().settings.hardware.printerMarginRight;
  double get printerMarginBottomSetting => getIt<SettingsManager>().settings.hardware.printerMarginBottom;
  double get printerMarginLeftSetting => getIt<SettingsManager>().settings.hardware.printerMarginLeft;
  int get printerQueueWarningThresholdSetting => getIt<SettingsManager>().settings.hardware.printerQueueWarningThreshold;
  String get firefoxSendServerUrlSetting => getIt<SettingsManager>().settings.output.firefoxSendServerUrl;
  int get firefoxSendControlCommandTimeoutSetting => getIt<SettingsManager>().settings.output.firefoxSendControlCommandTimeout.inSeconds;
  int get firefoxSendTransferTimeoutSetting => getIt<SettingsManager>().settings.output.firefoxSendTransferTimeout.inSeconds;
  ExportFormat get exportFormat => getIt<SettingsManager>().settings.output.exportFormat;
  int get jpgQuality => getIt<SettingsManager>().settings.output.jpgQuality;
  double get resolutionMultiplier => getIt<SettingsManager>().settings.output.resolutionMultiplier;
  bool get useFullFrame1PhotoLayout => getIt<SettingsManager>().settings.output.useFullFrame1PhotoLayout;
  @observable UniqueKey returnToHomeTimeoutSecondsKey = UniqueKey();
  int get returnToHomeTimeoutSeconds => getIt<SettingsManager>().settings.ui.returnToHomeTimeoutSeconds;
  bool get enableSfxSetting => getIt<SettingsManager>().settings.ui.enableSfx;
  String get clickSfxFileSetting => getIt<SettingsManager>().settings.ui.clickSfxFile;
  String get shareScreenSfxFileSetting => getIt<SettingsManager>().settings.ui.shareScreenSfxFile;
  Language get languageSetting => getIt<SettingsManager>().settings.ui.language;
  bool get allowScrollGestureWithMouse => getIt<SettingsManager>().settings.ui.allowScrollGestureWithMouse;
  ScreenTransitionAnimation get screenTransitionAnimation => getIt<SettingsManager>().settings.ui.screenTransitionAnimation;
  BackgroundBlur get backgroundBlur => getIt<SettingsManager>().settings.ui.backgroundBlur;
  FilterQuality get screenTransitionAnimationFilterQuality => getIt<SettingsManager>().settings.ui.screenTransitionAnimationFilterQuality;
  FilterQuality get liveViewFilterQuality => getIt<SettingsManager>().settings.ui.liveViewFilterQuality;
  bool get showSettingsButtonSetting => getIt<SettingsManager>().settings.ui.showSettingsButton;
  bool get showTouchIndicatorSetting => getIt<SettingsManager>().settings.ui.showTouchIndicator;
  bool get mqttIntegrationEnableSetting => getIt<SettingsManager>().settings.mqttIntegration.enable;
  String get mqttIntegrationHostSetting => getIt<SettingsManager>().settings.mqttIntegration.host;
  int get mqttIntegrationPortSetting => getIt<SettingsManager>().settings.mqttIntegration.port;
  bool get mqttIntegrationSecureSetting => getIt<SettingsManager>().settings.mqttIntegration.secure;
  bool get mqttIntegrationVerifyCertificateSetting => getIt<SettingsManager>().settings.mqttIntegration.verifyCertificate;
  bool get mqttIntegrationUseWebSocketSetting => getIt<SettingsManager>().settings.mqttIntegration.useWebSocket;
  String get mqttIntegrationUsernameSetting => getIt<SettingsManager>().settings.mqttIntegration.username;
  String get mqttIntegrationClientIdSetting => getIt<SettingsManager>().settings.mqttIntegration.clientId;
  String get mqttIntegrationRootTopicSetting => getIt<SettingsManager>().settings.mqttIntegration.rootTopic;
  bool get mqttIntegrationEnableHomeAssistantDiscoverySetting => getIt<SettingsManager>().settings.mqttIntegration.enableHomeAssistantDiscovery;
  String get mqttIntegrationHomeAssistantDiscoveryTopicPrefixSetting => getIt<SettingsManager>().settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
  String get mqttIntegrationHomeAssistantComponentIdSetting => getIt<SettingsManager>().settings.mqttIntegration.homeAssistantComponentId;
  List<ExternalSystemCheckSetting> get externalSystemChecks => getIt<SettingsManager>().settings.externalSystemChecks;
  int get externalSystemCheckIntervalSeconds => getIt<SettingsManager>().settings.externalSystemCheckIntervalSeconds;
  bool get faceRecognitionEnabled => getIt<SettingsManager>().settings.faceRecognition.enable;
  String get faceRecognitionServerUrlSetting => getIt<SettingsManager>().settings.faceRecognition.serverUrl;
  bool get debugShowFpsCounter => getIt<SettingsManager>().settings.debug.showFpsCounter;
  ColorVisionDeficiency get simulateCvd => getIt<SettingsManager>().settings.debug.simulateCvd;
  int get simulateCvdSeverity => getIt<SettingsManager>().settings.debug.simulateCvdSeverity;
  bool get enableExtensivePrintJobLog => getIt<SettingsManager>().settings.debug.enableExtensivePrintJobLog;
  bool get enableVideoModeSetting => getIt<SettingsManager>().settings.debug.enableVideoMode;
  int get videoDurationSetting => getIt<SettingsManager>().settings.debug.videoDuration;

  double get outputResHeightExcl => resolutionMultiplier * 1000;
  double get outputResWidthExcl => outputResHeightExcl/collageAspectRatioSetting;
  double get outputResHeightIncl => outputResHeightExcl + collagePaddingSetting * 2 * resolutionMultiplier;
  double get outputResWidthIncl => outputResWidthExcl + collagePaddingSetting * 2 * resolutionMultiplier;

  // Initializers/Deinitializers

  SettingsOverlayViewModelBase({
    required super.contextAccessor,
  }) {
    setFlutterPrintingQueueList();
    setCupsQueueList();
    setWebcamList();
    setWebcamList2();
    setCameraList();
    setCameraList2();
    setCupsPageSizeOptions();
  }

  // Methods

  Future<void> updateSettings(UpdateSettingsCallback updateCallback) async {
    Settings currentSettings = getIt<SettingsManager>().settings;
    Settings updatedSettings = updateCallback(currentSettings);
    await getIt<SettingsManager>().updateAndSave(updatedSettings);
  }

  Future<void> updateProjectSettings(UpdateProjectSettingsCallback updateCallback) async {
    ProjectSettings currentSettings = getIt<ProjectManager>().settings;
    ProjectSettings updatedSettings = updateCallback(currentSettings);
    await getIt<ProjectManager>().updateAndSave(updatedSettings);
  }

}
