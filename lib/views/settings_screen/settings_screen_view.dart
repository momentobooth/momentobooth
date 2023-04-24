import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
          return _navigationView;
        },
      ),
    );
  }

  Widget get _navigationView {
    return Observer(
      builder: (context) {
        return NavigationView(
          pane: NavigationPane(
            selected: viewModel.paneIndex,
            onChanged: controller.onNavigationPaneIndexChanged,
            items: [
              PaneItemSeparator(color: Colors.transparent),
              PaneItem(
                icon: Icon(FluentIcons.settings),
                title: Text("General"),
                body: Builder(builder: (_) => _getGeneralSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: Icon(FluentIcons.devices4),
                title: Text("Hardware"),
                body: Builder(builder: (_) => _getHardwareSettings(viewModel, controller)),
              ),
              PaneItem(
                icon: Icon(FluentIcons.send),
                title: Text("Output"),
                body: Builder(builder: (_) => _getOutputSettings(viewModel, controller)),
              ),
            ],
            footerItems: [
              PaneItem(
                icon: Icon(FluentIcons.data_flow),
                title: Text("Log"),
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
      child: LoggyStreamWidget(),
    );
  }

}
