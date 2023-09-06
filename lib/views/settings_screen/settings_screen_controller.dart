import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreenController extends ScreenControllerBase<SettingsScreenViewModel> with UiLoggy {

  final comboboxKey = GlobalKey<ComboBoxState>(debugLabel: 'Combobox Key');

  TextEditingController? _captureLocationController;
  TextEditingController get captureLocationController => _captureLocationController ??= TextEditingController(text: viewModel.captureLocationSetting);

  TextEditingController? _localFolderController;
  TextEditingController get localFolderSettingController => _localFolderController ??= TextEditingController(text: viewModel.localFolderSetting);

  TextEditingController? _templatesFolderController;
  TextEditingController get templatesFolderSettingController => _templatesFolderController ??= TextEditingController(text: viewModel.templatesFolderSetting);

  TextEditingController? _firefoxSendServerUrlController;
  TextEditingController get firefoxSendServerUrlController => _firefoxSendServerUrlController ??= TextEditingController(text: viewModel.firefoxSendServerUrlSetting);
  
  TextEditingController? _gPhoto2CaptureTargetController;
  TextEditingController get gPhoto2CaptureTargetController => _gPhoto2CaptureTargetController ??= TextEditingController(text: viewModel.gPhoto2CaptureTargetSetting);

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

  void onLiveViewFlipImageChanged(Flip? liveViewFlipImage) {
    if (liveViewFlipImage != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewFlipImage: liveViewFlipImage));
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
      viewModel.updateSettings((settings) => settings.copyWith.hardware(pageHeight: pageWidth));
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

}
