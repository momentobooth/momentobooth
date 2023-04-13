import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_view_model.dart';

part 'settings_screen_view.helpers.dart';

class SettingsScreenView extends ScreenViewBase<SettingsScreenViewModel, SettingsScreenController> {

  const SettingsScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return FluentTheme(
      data: FluentThemeData(),
      child: Builder(
        builder: (context) {
          return Observer(builder: (_) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _navigationView),
              ],
            );
          });
        },
      ),
    );
  }

  Widget get _navigationView {
    return NavigationView(
      pane: NavigationPane(
        selected: viewModel.paneIndex,
        onChanged: controller.onNavigationPaneIndexChanged,
        items: [
          PaneItemSeparator(color: Colors.transparent),
          PaneItem(
            icon: Icon(FluentIcons.settings),
            title: Text("General"),
            body: _generalSettings,
          ),
          PaneItem(
            icon: Icon(FluentIcons.devices4),
            title: Text("Hardware"),
            body: _hardwareSettings,
          ),
          PaneItem(
            icon: Icon(FluentIcons.send),
            title: Text("Output"),
            body: _outputSettings,
          ),
        ],
      ),
    );
  }

  Widget get _generalSettings {
    return FluentSettingsPage(
      title: "General",
      blocks: [
        FluentSettingsBlock(
          title: "Settings",
          settings: [
            _getInput(
              icon: FluentIcons.timer,
              title: "Capture delay",
              subtitle: 'In seconds',
              value: () => viewModel.captureDelaySecondsSetting,
              onChanged: controller.onCaptureDelaySecondsChanged,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Hit Ctrl+F or Alt+Enter to toggle fullscreen mode."),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _hardwareSettings {
    return FluentSettingsPage(
      title: "Hardware",
      blocks: [
        FluentSettingsBlock(
          title: "Camera settings",
          settings: [
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Live view method",
              subtitle: "Method used for live previewing",
              items: viewModel.liveViewMethods,
              value: () => viewModel.liveViewMethodSetting,
              onChanged: controller.onLiveViewMethodChanged,
            ),
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Capture method",
              subtitle: "Method used for capturing final images",
              items: viewModel.captureMethods,
              value: () => viewModel.captureMethodSetting,
              onChanged: controller.onCaptureMethodChanged,
            ),
            _getTextInput(
              icon: FluentIcons.folder,
              title: "Capture location",
              subtitle: "Location to look for captured images",
              controller: controller.captureLocationController,
              onChanged: controller.onCaptureLocationChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Printing",
          settings: [
            FluentSettingCard(
              icon: FluentIcons.print,
              title: "Printer",
              subtitle: "Which printer to use for printing photos",
              child: Row(
                children: [
                  Button(
                    onPressed: viewModel.setPrinterList,
                    // style: ButtonStyle(backgroundColor: ButtonState.all(Colors.white)),
                    child: const Text('Refresh'),
                  ),
                  SizedBox(width: 10,),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 150),
                    child: Observer(builder: (_) {
                      return ComboBox<String>(
                        items: viewModel.printerOptions,
                        value: viewModel.printerSetting,
                        onChanged: controller.onPrinterChanged,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _outputSettings {
    return FluentSettingsPage(
      title: "Output",
      blocks: [
        FluentSettingsBlock(
          title: "Local",
          settings: [
            _getTextInput(
              icon: FluentIcons.fabric_picture_library,
              title: "Local photo storage location",
              subtitle: "Location where the output images will be stored",
              controller: controller.localFolderSettingController,
              onChanged: controller.onLocalFolderChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Share using internet",
          settings: [
            _getTextInput(
              icon: FluentIcons.my_network,
              title: "Firefox Send URL",
              subtitle: "Firefox Send Server URL",
              controller: controller.firefoxSendServerUrlController,
              onChanged: controller.onFirefoxSendServerUrlChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Image settings",
          settings: [
            _getComboBoxCard(
              icon: FluentIcons.file_image,
              title: "Image file type",
              subtitle: "What kind of file to generate",
              items: viewModel.exportFormats,
              value: () => viewModel.exportFormat,
              onChanged: controller.onExportFormatChanged,
            ),
            _getInput(
              icon: FluentIcons.equalizer,
              title: "JPG quality",
              subtitle: 'Export quality (higher is bigger files)',
              value: () => viewModel.jpgQuality,
              onChanged: controller.onJpgQualityChanged,
            ),
            _getInput(
              icon: FluentIcons.picture_stretch,
              title: "Output resolution multiplier",
              subtitle: 'Controls image resolution',
              value: () => viewModel.resolutionMultiplier,
              onChanged: controller.onResolutionMultiplierChanged,
              smallChange: 0.1,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Output resolution will be ${(viewModel.resolutionMultiplier*1000).round()}×${(viewModel.resolutionMultiplier*2000/3).round()}"),
            ),
          ],
        ),
      ],
    );
  }

}
