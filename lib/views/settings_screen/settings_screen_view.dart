import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/secret/secret_repository.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:momento_booth/views/custom_widgets/indicators/connection_state_indicator.dart';
import 'package:momento_booth/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';
import 'package:momento_booth/views/settings_screen/widgets/boolean_input_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/button_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/color_input_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/combo_box_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/file_picker_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/folder_picker_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/number_input_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/secret_input_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/text_display_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/text_input_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'settings_screen_view.debug.dart';
part 'settings_screen_view.stats.dart';
part 'settings_screen_view.face_recognition.dart';
part 'settings_screen_view.general.dart';
part 'settings_screen_view.hardware.dart';
part 'settings_screen_view.mqtt_integration.dart';
part 'settings_screen_view.output.dart';
part 'settings_screen_view.templating.dart';
part 'settings_screen_view.ui.dart';

class SettingsScreenView extends ScreenViewBase<SettingsScreenViewModel, SettingsScreenController> {

  const SettingsScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Observer(
      builder: (context) {
        return NavigationView(
          pane: NavigationPane(
            selected: viewModel.paneIndex,
            onChanged: controller.onNavigationPaneIndexChanged,
            items: [
              PaneItemSeparator(color: Colors.transparent),
              PaneItem(
                icon: const Icon(FluentIcons.settings),
                title: const Text("General"),
                body: Builder(builder: (_) => _getGeneralSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.devices4),
                title: const Text("Hardware"),
                body: Builder(builder: (_) => _getHardwareSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.send),
                title: const Text("Output"),
                body: Builder(builder: (_) => _getOutputSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.open_in_new_window),
                title: const Text("User interface"),
                body: Builder(builder: (_) => _getUiSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.design),
                title: const Text("Templating"),
                body: Builder(builder: (_) => _getTemplatingSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.automate_flow),
                title: const Text("MQTT integration"),
                body: Builder(builder: (_) => _getMqttIntegrationSettings(viewModel, controller)),
                infoBadge: const MqttConnectionStateIndicator(),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.diamond_user),
                title: const Text("Face recognition"),
                body: Builder(builder: (_) => _getFaceRecognitionSettings(viewModel, controller)),
              ),
            ],
            footerItems: [
              PaneItem(
                icon: const Icon(FluentIcons.chart),
                title: const Text("Statistics"),
                body: Builder(builder: (_) => _getStatsTab(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.device_bug),
                title: const Text("Debug"),
                body: Builder(builder: (_) => _getDebugTab(viewModel, controller)),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.data_flow),
                title: const Text("Log"),
                body: Builder(builder: (_) => _log),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get _log {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ScaffoldMessenger(
        child: TalkerScreen(
          talker: getIt<Talker>(),
          theme: TalkerScreenTheme(
            backgroundColor: FluentTheme.of(context).navigationPaneTheme.backgroundColor!,
            textColor: FluentTheme.of(context).typography.body!.color!,
            cardColor: FluentTheme.of(context).cardColor,
          ),
          appBarLeading: const SizedBox(),
          appBarTitle: '',
        ),
      ),
    );
  }

}
