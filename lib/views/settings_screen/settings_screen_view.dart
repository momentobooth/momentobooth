import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:momento_booth/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

part 'settings_screen_view.helpers.dart';
part 'settings_screen_view.general.dart';
part 'settings_screen_view.hardware.dart';
part 'settings_screen_view.output.dart';
part 'settings_screen_view.debug.dart';
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
                title: const Text("UI"),
                body: Builder(builder: (_) => _getUiSettings(viewModel, controller)),
              ),
            ],
            footerItems: [
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
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: LoggyStreamWidget(),
    );
  }

}
