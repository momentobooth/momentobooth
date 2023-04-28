import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreenController extends ScreenControllerBase<SettingsScreenViewModel> {

  final comboboxKey = GlobalKey<ComboBoxState>(debugLabel: 'Combobox Key');

  TextEditingController? _captureLocationController;
  TextEditingController get captureLocationController => _captureLocationController ??= TextEditingController(text: viewModel.captureLocationSetting);

  TextEditingController? _localFolderController;
  TextEditingController get localFolderSettingController => _localFolderController ??= TextEditingController(text: viewModel.localFolderSetting);

  TextEditingController? _templatesFolderController;
  TextEditingController get templatesFolderSettingController => _templatesFolderController ??= TextEditingController(text: viewModel.templatesFolderSetting);

  TextEditingController? _firefoxSendServerUrlController;
  TextEditingController get firefoxSendServerUrlController => _firefoxSendServerUrlController ??= TextEditingController(text: viewModel.firefoxSendServerUrlSetting);

  // Initialization/Deinitialization

  SettingsScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onNavigationPaneIndexChanged(int newIndex) {
    viewModel.paneIndex = newIndex;
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

  void onDisplayConfettiChanged(bool? displayConfetti) {
    if (displayConfetti != null) {
      viewModel.updateSettings((settings) => settings.copyWith(displayConfetti: displayConfetti));
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

  void onPrinterChanged(String? printerName) {
    if (printerName != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(printerName: printerName));
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

}
