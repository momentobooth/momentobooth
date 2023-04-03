import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_view_model.dart';

class SettingsScreenController extends ScreenControllerBase<SettingsScreenViewModel> {

  final comboboxKey = GlobalKey<ComboBoxState>(debugLabel: 'Combobox Key');

  TextEditingController? _captureLocationController;
  TextEditingController get captureLocationController => _captureLocationController ??= TextEditingController(text: viewModel.captureLocationSetting);

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

  void onLiveViewMethodChanged(LiveViewMethod? liveViewMethod) {
    if (liveViewMethod != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(liveViewMethod: liveViewMethod));
    }
  }

  void onCaptureMethodChanged(CaptureMethod? captureMethod) {
    if (captureMethod != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureMethod: captureMethod));
    }
  }

  void onCaptureLocationChanged(String? captureLocation) {
    if (captureLocation != null) {
      viewModel.updateSettings((settings) => settings.copyWith.hardware(captureLocation: captureLocation));
    }
  }

  void onFirefoxSendServerUrlChanged(String? firefoxSendServerUrl) {
    if (firefoxSendServerUrl != null) {
      viewModel.updateSettings((settings) => settings.copyWith.output(firefoxSendServerUrl: firefoxSendServerUrl));
    }
  }

}
