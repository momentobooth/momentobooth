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
            icon: Icon(FluentIcons.public_email),
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
          icon: FluentIcons.camera,
          title: "Settings",
          settings: [
            _getInput(
              icon: FluentIcons.timer,
              title: "Capture delay",
              subtitle: 'In seconds',
              value: () => viewModel.captureDelaySecondsSetting,
              onChanged: controller.onCaptureDelaySecondsChanged,
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
          icon: FluentIcons.camera,
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
      ],
    );
  }

  Widget get _outputSettings {
    return FluentSettingsPage(
      title: "Output",
      blocks: [
        FluentSettingsBlock(
          icon: FluentIcons.internet_sharing,
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
      ],
    );
  }

}
