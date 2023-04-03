import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/models/settings.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_view_model.dart';

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
            FluentSettingCard(
              icon: FluentIcons.timer,
              title: "Capture delay",
              subtitle: 'In seconds',
              child: SizedBox(
                width: 150,
                child: Observer(builder: (_) {
                  return NumberBox(
                    value: viewModel.captureDelaySecondsSetting,
                    onChanged: controller.onCaptureDelaySecondsChanged,
                  );
                }),
              ),
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
            FluentSettingCard(
              icon: FluentIcons.camera,
              title: "Live view method",
              subtitle: "Method used for live previewing",
              child: Observer(builder: (_) {
                return ComboBox<LiveViewMethod>(
                  items: viewModel.liveViewMethods,
                  value: viewModel.liveViewMethodSetting,
                  onChanged: controller.onLiveViewMethodChanged,
                );
              }),
            ),
            FluentSettingCard(
              icon: FluentIcons.camera,
              title: "Capture method",
              subtitle: "Method used for capturing final images",
              child: Observer(builder: (_) {
                return ComboBox<CaptureMethod>(
                  items: viewModel.captureMethods,
                  value: viewModel.captureMethodSetting,
                  onChanged: controller.onCaptureMethodChanged,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
