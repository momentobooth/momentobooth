import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreenController extends ScreenControllerBase<SettingsScreenViewModel> with UiLoggy {

  final comboboxKey = GlobalKey<ComboBoxState>(debugLabel: 'Combobox Key');

  TextEditingController? _clickSfxFileController;
  TextEditingController get clickSfxFileController => _clickSfxFileController ??= TextEditingController(text: viewModel.clickSfxFileSetting);

  TextEditingController? _shareScreenSfxFileController;
  TextEditingController get shareScreenSfxFileController => _shareScreenSfxFileController ??= TextEditingController(text: viewModel.shareScreenSfxFileSetting);

  TextEditingController? _captureLocationController;
  TextEditingController get captureLocationController => _captureLocationController ??= TextEditingController(text: viewModel.captureLocationSetting);

  TextEditingController? _captureStorageLocationController;
  TextEditingController get captureStorageLocationController => _captureStorageLocationController ??= TextEditingController(text: viewModel.captureStorageLocationSetting);

  TextEditingController? _localFolderController;
  TextEditingController get localFolderSettingController => _localFolderController ??= TextEditingController(text: viewModel.localFolderSetting);

  TextEditingController? _templatesFolderController;
  TextEditingController get templatesFolderSettingController => _templatesFolderController ??= TextEditingController(text: viewModel.templatesFolderSetting);

  TextEditingController? _firefoxSendServerUrlController;
  TextEditingController get firefoxSendServerUrlController => _firefoxSendServerUrlController ??= TextEditingController(text: viewModel.firefoxSendServerUrlSetting);
  
  TextEditingController? _gPhoto2CaptureTargetController;
  TextEditingController get gPhoto2CaptureTargetController => _gPhoto2CaptureTargetController ??= TextEditingController(text: viewModel.gPhoto2CaptureTargetSetting);

  TextEditingController? _mqttIntegrationHostController;
  TextEditingController get mqttIntegrationHostController => _mqttIntegrationHostController ??= TextEditingController(text: viewModel.mqttIntegrationHostSetting);

  TextEditingController? _mqttIntegrationUsernameController;
  TextEditingController get mqttIntegrationUsernameController => _mqttIntegrationUsernameController ??= TextEditingController(text: viewModel.mqttIntegrationUsernameSetting);

  TextEditingController? _mqttIntegrationPasswordController;
  TextEditingController get mqttIntegrationPasswordController => _mqttIntegrationPasswordController ??= TextEditingController(text: viewModel.mqttIntegrationPasswordSetting);

  TextEditingController? _mqttIntegratonClientIdController;
  TextEditingController get mqttIntegrationClientIdController => _mqttIntegratonClientIdController ??= TextEditingController(text: viewModel.mqttIntegrationClientIdSetting);

  TextEditingController? _mqttIntegrationRootTopicController;
  TextEditingController get mqttIntegrationRootTopicController => _mqttIntegrationRootTopicController ??= TextEditingController(text: viewModel.mqttIntegrationRootTopicSetting);

  TextEditingController? _mqttIntegrationHomeAssistantDiscoveryTopicPrefixController;
  TextEditingController get mqttIntegrationHomeAssistantDiscoveryTopicPrefixController => _mqttIntegrationHomeAssistantDiscoveryTopicPrefixController ??= TextEditingController(text: viewModel.mqttIntegrationHomeAssistantDiscoveryTopicPrefixSetting);

  TextEditingController? _mqttIntegrationHomeAssistantComponentIdController;
  TextEditingController get mqttIntegrationHomeAssistantComponentIdController => _mqttIntegrationHomeAssistantComponentIdController ??= TextEditingController(text: viewModel.mqttIntegrationHomeAssistantComponentIdSetting);

  // Initialization/Deinitialization

  SettingsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onNavigationPaneIndexChanged(int newIndex) {
    viewModel.paneIndex = newIndex;
  }

  Future<void> exportTemplate() async {
    final stopwatch = Stopwatch()..start();
    final pixelRatio = viewModel.resolutionMultiplier;
    final format = viewModel.exportFormat;
    final jpgQuality = viewModel.jpgQuality;
    PhotosManager.instance.outputImage = await viewModel.collageKey.currentState!.getCollageImage(pixelRatio: pixelRatio, format: format, jpgQuality: jpgQuality);
    loggy.debug('captureCollage took ${stopwatch.elapsed}');
    
    File? file = await PhotosManager.instance.writeOutput(advance: true);
    loggy.debug("Wrote template debug export output to ${file?.path}");
  }

  void onCaptureDelaySecondsChanged(int? captureDelaySeconds) {
    if (captureDelaySeconds != null) {
      viewModel.updateSettings((settings) => settings.copyWith(captureDelaySeconds: captureDelaySeconds));
    }
  }

  void onCollageAspectRatioChanged(double? collageAspectRatio) {
    if (collageAspectRatio != null) {
      viewModel.updateSettings((settings) => settings.copyWith(collageAspectRatio: collageAspectRatio));
    }
  }

  void onCollagePaddingChanged(double? collagePadding) {
    if (collagePadding != null) {
      viewModel.updateSettings((settings) => settings.copyWith(collagePadding: collagePadding));
    }
  }

  void onSinglePhotoIsCollageChanged(bool? singlePhotoIsCollage) {
    if (singlePhotoIsCollage != null) {
      viewModel.updateSettings((settings) => settings.copyWith(singlePhotoIsCollage: singlePhotoIsCollage));
    }
  }

  void onTemplatesFolderChanged(String? templatesFolder) {
    if (templatesFolder != null) {
      viewModel.updateSettings((settings) => settings.copyWith(templatesFolder: templatesFolder));
    }
  }

  void onLiveViewAndCaptureRotateChanged(Rotate? liveViewAndCaptureRotate) {
    if (liveViewAndCaptureRotate != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewAndCaptureRotate: liveViewAndCaptureRotate));
    }
  }

  void onLiveViewFlipChanged(Flip? liveViewFlip) {
    if (liveViewFlip != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewFlip: liveViewFlip));
    }
  }

  void onCaptureFlipChanged(Flip? captureFlip) {
    if (captureFlip != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureFlip: captureFlip));
    }
  }

  void onLiveViewAndCaptureAspectRatioChanged(double? liveViewAndCaptureAspectRatio) {
    if (liveViewAndCaptureAspectRatio != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewAndCaptureAspectRatio: liveViewAndCaptureAspectRatio));
    }
  }

  void onLiveViewMethodChanged(LiveViewMethod? liveViewMethod) {
    if (liveViewMethod != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: liveViewMethod));
    }
  }

  void onLiveViewWebcamIdChanged(String? liveViewWebcamId) {
    if (liveViewWebcamId != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewWebcamId: liveViewWebcamId));
    }
  }

  void onCaptureMethodChanged(CaptureMethod? captureMethod) {
    if (captureMethod != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureMethod: captureMethod));
    }
  }

  void onGPhoto2CameraIdChanged(String? gPhoto2CameraId) {
    if (gPhoto2CameraId != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(gPhoto2CameraId: gPhoto2CameraId));
    }
  }

  void onGPhoto2SpecialHandlingChanged(GPhoto2SpecialHandling? gPhoto2SpecialHandling) {
    if (gPhoto2SpecialHandling != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(gPhoto2SpecialHandling: gPhoto2SpecialHandling));
    }
  }

  void onGPhoto2CaptureTargetChanged(String? gPhoto2CaptureTarget) {
    if (gPhoto2CaptureTarget != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(gPhoto2CaptureTarget: gPhoto2CaptureTarget));
    }
  }

  void onGPhoto2DownloadExtraFilesChanged(bool? gPhoto2DownloadExtraFiles) {
    if (gPhoto2DownloadExtraFiles != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(gPhoto2DownloadExtraFiles: gPhoto2DownloadExtraFiles));
    }
  }

  void onGPhoto2AutoFocusMsBeforeCaptureChanged(int? gPhoto2AutoFocusMsBeforeCapture) {
    if (gPhoto2AutoFocusMsBeforeCapture != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(gPhoto2AutoFocusMsBeforeCapture: gPhoto2AutoFocusMsBeforeCapture));
    }
  }
  
  void onCaptureDelayGPhoto2Changed(int? captureDelayGPhoto2) {
    if (captureDelayGPhoto2 != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureDelayGPhoto2: captureDelayGPhoto2));
    }
  }

  void onCaptureDelaySonyChanged(int? captureDelaySony) {
    if (captureDelaySony != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureDelaySony: captureDelaySony));
    }
  }

  void onCaptureLocationChanged(String? captureLocation) {
    if (captureLocation != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureLocation: captureLocation));
    }
  }

  void onSaveCapturesToDiskChanged(bool? saveCapturesToDisk) {
    if (saveCapturesToDisk != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(saveCapturesToDisk: saveCapturesToDisk));
    }
  }

  void onCaptureStorageLocationChanged(String? captureStorageLocation) {
    if (captureStorageLocation != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureStorageLocation: captureStorageLocation));
    }
  }

  void onPrinterChanged(String? printerName, int? printerIndex) {
    if (printerName != null && printerIndex != null) {
      List<String> currentList = List.from(viewModel.printersSetting);
      
      if (printerName == viewModel.unsedPrinterValue) {
        currentList.length = printerIndex;
      } else {
        if (printerIndex >= currentList.length) {
          currentList.add(printerName);
        } else {
          currentList[printerIndex] = printerName;
        }
      }
      loggy.debug("Setting printerlist to $currentList");
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerNames: currentList));
    }
  }

  void onPageHeightChanged(double? pageHeight) {
    if (pageHeight != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(pageHeight: pageHeight));
    }
  }

  void onPageWidthChanged(double? pageWidth) {
    if (pageWidth != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(pageWidth: pageWidth));
    }
  }

  void onUsePrinterSettingsChanged(bool? usePrinterSettings) {
    if (usePrinterSettings != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(usePrinterSettings: usePrinterSettings));
    }
  }

  void onPrinterMarginTopChanged(double? marginTop) {
    if (marginTop != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerMarginTop: marginTop));
    }
  }

  void onPrinterMarginRightChanged(double? marginRight) {
    if (marginRight != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerMarginRight: marginRight));
    }
  }

  void onPrinterMarginBottomChanged(double? marginBottom) {
    if (marginBottom != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerMarginBottom: marginBottom));
    }
  }

  void onPrinterMarginLeftChanged(double? marginLeft) {
    if (marginLeft != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerMarginLeft: marginLeft));
    }
  }

  void onPrinterQueueWarningThresholdChanged(int? warningThreshold) {
    if (warningThreshold != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerQueueWarningThreshold: warningThreshold));
    }
  }

  void onLocalFolderChanged(String? localFolder) {
    if (localFolder != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(localFolder: localFolder));
    }
  }

  void onFirefoxSendServerUrlChanged(String? firefoxSendServerUrl) {
    if (firefoxSendServerUrl != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(firefoxSendServerUrl: firefoxSendServerUrl));
    }
  }

  void onExportFormatChanged(ExportFormat? exportFormat) {
    if (exportFormat != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(exportFormat: exportFormat));
    }
  }

  void onJpgQualityChanged(int? jpgQuality) {
    if (jpgQuality != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(jpgQuality: jpgQuality));
    }
  }

  void onResolutionMultiplierChanged(double? resolutionMultiplier) {
    if (resolutionMultiplier != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(resolutionMultiplier: resolutionMultiplier));
    }
  }

  void onDisplayConfettiChanged(bool? displayConfetti) {
    if (displayConfetti != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(displayConfetti: displayConfetti));
    }
  }

  void onEnableSfxChanged(bool? enableSfx) {
    if (enableSfx != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(enableSfx: enableSfx));
    }
  }

  void onClickSfxFileChanged(String? clickSfxFile) {
    if (clickSfxFile != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(clickSfxFile: clickSfxFile));
    }
  }

  void onShareScreenSfxFileChanged(String? shareScreenSfxFile) {
    if (shareScreenSfxFile != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(shareScreenSfxFile: shareScreenSfxFile));
    }
  }

  void onLanguageChanged(Language? language) {
    if (language != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(language: language));
    }
  }

  void onScreenTransitionAnimationChanged(ScreenTransitionAnimation? screenTransitionAnimation) {
    if (screenTransitionAnimation != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(screenTransitionAnimation: screenTransitionAnimation));
    }
  }

  void onBackgroundBlurChanged(BackgroundBlur? backgroundBlur) {
    if (backgroundBlur != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(backgroundBlur: backgroundBlur));
    }
  }

  void onScreenTransitionAnimationFilterQualityChanged(FilterQuality? filterQuality) {
    if (filterQuality != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(screenTransitionAnimationFilterQuality: filterQuality));
    }
  }

  void onLiveViewFilterQualityChanged(FilterQuality? filterQuality) {
    if (filterQuality != null) {
      viewModel.updateSettings((settings) => settings.copyWith.ui(liveViewFilterQuality: filterQuality));
    }
  }

  void onMqttIntegrationEnableChanged(bool? enable) {
    if (enable != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(enable: enable));
    }
  }

  void onMqttIntegrationHostChanged(String? host) {
    if (host != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(host: host, enable: false));
    }
  }

  void onMqttIntegrationPortChanged(int? port) {
    if (port != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(port: port, enable: false));
    }
  }

  void onMqttIntegrationSecureChanged(bool? secure) {
    if (secure != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(secure: secure, enable: false));
    }
  }

  void onMqttIntegrationVerifyCertificateChanged(bool? verifyCertificate) {
    if (verifyCertificate != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(verifyCertificate: verifyCertificate, enable: false));
    }
  }

  void onMqttIntegrationUseWebSocketChanged(bool? useWebSocket) {
    if (useWebSocket != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(useWebSocket: useWebSocket, enable: false));
    }
  }

  void onMqttIntegrationUsernameChanged(String? username) {
    if (username != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(username: username, enable: false));
    }
  }

  void onMqttIntegrationPasswordChanged(String? password) {
    if (password != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(password: password, enable: false));
    }
  }

  void onMqttIntegrationClientIdChanged(String? clientId) {
    if (clientId != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(clientId: clientId, enable: false));
    }
  }

  void onMqttIntegrationRootTopicChanged(String? rootTopic) {
    if (rootTopic != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(rootTopic: rootTopic, enable: false));
    }
  }

  void onMqttIntegrationEnableHomeAssistantDiscoveryChanged(bool? enableHomeAssistantDiscovery) {
    if (enableHomeAssistantDiscovery != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(enableHomeAssistantDiscovery: enableHomeAssistantDiscovery, enable: false));
    }
  }

  void onMqttIntegrationHomeAssistantDiscoveryTopicPrefixChanged(String? homeAssistantDiscoveryTopicPrefix) {
    if (homeAssistantDiscoveryTopicPrefix != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(homeAssistantDiscoveryTopicPrefix: homeAssistantDiscoveryTopicPrefix, enable: false));
    }
  }

  void onMqttIntegrationHomeAssistantComponentIdChanged(String? homeAssistantComponentId) {
    if (homeAssistantComponentId != null) {
      viewModel.updateSettings((settings) => settings.copyWith.mqttIntegration(homeAssistantComponentId: homeAssistantComponentId, enable: false));
    }
  }

  void onDebugShowFpsCounterChanged(bool? showFpsCounter) {
    if (showFpsCounter != null) {
      viewModel.updateSettings((settings) => settings.copyWith.debug(showFpsCounter: showFpsCounter));
    }
  }

}
