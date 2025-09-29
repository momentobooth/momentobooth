import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger;
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/managers/external_system_status_manager.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/components/indicators/connection_state_indicator.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_icon.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_list.dart';
import 'package:momento_booth/views/settings_overlay/components/aspect_ratio_preview.dart';
import 'package:momento_booth/views/settings_overlay/components/import_field.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_action_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_color_pick_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_combo_box_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_file_select_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_folder_select_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_number_edit_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_secret_edit_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_text_display_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_text_edit_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_toggle_tile.dart';
import 'package:momento_booth/views/settings_overlay/components/settings_list_page.dart';
import 'package:momento_booth/views/settings_overlay/components/settings_page.dart';
import 'package:momento_booth/views/settings_overlay/components/settings_section.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_controller.dart';
import 'package:momento_booth/views/settings_overlay/settings_overlay_view_model.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'pages/settings_overlay_view.about.dart';
part 'pages/settings_overlay_view.debug.dart';
part 'pages/settings_overlay_view.face_recognition.dart';
part 'pages/settings_overlay_view.general.dart';
part 'pages/settings_overlay_view.hardware.dart';
part 'pages/settings_overlay_view.import.dart';
part 'pages/settings_overlay_view.mqtt_integration.dart';
part 'pages/settings_overlay_view.output.dart';
part 'pages/settings_overlay_view.project.dart';
part 'pages/settings_overlay_view.quick_settings.dart';
part 'pages/settings_overlay_view.stats.dart';
part 'pages/settings_overlay_view.subsystem_status.dart';
part 'pages/settings_overlay_view.templating.dart';
part 'pages/settings_overlay_view.ui.dart';

class SettingsOverlayView extends ScreenViewBase<SettingsOverlayViewModel, SettingsOverlayController> {

  final GlobalKey<NavigationViewState> _navigationPaneKey = GlobalKey();

  SettingsOverlayView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
    required SettingsPageKey initialPage,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationPane pane = _navigationPaneKey.currentState!.widget.pane!;
      pane.changeTo(pane.allItems.firstWhere((item) => (item.key as ValueKey?)?.value == initialPage));
    });
  }

  @override
  Widget get body {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Observer(
        builder: (context) {
          return NavigationView(
            key: _navigationPaneKey,
            pane: NavigationPane(
              selected: viewModel.paneIndex,
              onChanged: controller.onNavigationPaneIndexChanged,
              items: [
                PaneItemSeparator(color: Colors.transparent),
                PaneItem(
                  key: ValueKey(SettingsPageKey.quickSettings),
                  icon: const Icon(LucideIcons.star),
                  title: const Text("Quick Settings"),
                  body: Builder(builder: (_) => _getQuickSettings(viewModel, controller)),
                ),
                PaneItemHeader(header: const Text('Project')),
                PaneItem(
                  key: ValueKey(SettingsPageKey.project),
                  icon: const Icon(LucideIcons.folderCog),
                  title: const Text("Project"),
                  body: Builder(builder: (_) => _getProjectSettings(viewModel, controller)),
                ),
                PaneItemHeader(header: const Text('App')),
                PaneItem(
                  key: ValueKey(SettingsPageKey.import),
                  icon: const Icon(LucideIcons.import),
                  title: const Text("Import"),
                  body: Builder(builder: (_) => _getImportSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.general),
                  icon: const Icon(LucideIcons.settings),
                  title: const Text("General"),
                  body: Builder(builder: (_) => _getGeneralSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.hardware),
                  icon: const Icon(LucideIcons.cable),
                  title: const Text("Hardware"),
                  body: Builder(builder: (_) => _getHardwareSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.output),
                  icon: const Icon(LucideIcons.send),
                  title: const Text("Output"),
                  body: Builder(builder: (_) => _getOutputSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.ui),
                  icon: const Icon(LucideIcons.appWindow),
                  title: const Text("User interface"),
                  body: Builder(builder: (_) => _getUiSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.templating),
                  icon: const Icon(LucideIcons.layoutTemplate),
                  title: const Text("Templating"),
                  body: Builder(builder: (_) => _getTemplatingSettings(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.mqtt),
                  icon: const Icon(LucideIcons.workflow),
                  title: const Text("MQTT integration"),
                  body: Builder(builder: (_) => _getMqttIntegrationSettings(viewModel, controller)),
                  infoBadge: const MqttConnectionStateIndicator(),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.faceRecognition),
                  icon: const Icon(LucideIcons.scanFace),
                  title: const Text("Face recognition"),
                  body: Builder(builder: (_) => _getFaceRecognitionSettings(viewModel, controller)),
                ),
              ],
              footerItems: [
                PaneItem(
                  key: ValueKey(SettingsPageKey.subsystemStatus),
                  icon: const Icon(LucideIcons.messageSquareWarning),
                  title: const Text("Subsystem status"),
                  body: Builder(builder: (context) => _getSubsystemStatusTab(viewModel, controller, context)),
                  infoBadge: SubsystemStatusIcon(status: viewModel.badgeStatus),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.stats),
                  icon: const Icon(LucideIcons.chartLine),
                  title: const Text("Statistics"),
                  body: Builder(builder: (_) => _getStatsTab(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.debug),
                  icon: const Icon(LucideIcons.bug),
                  title: const Text("Debug"),
                  body: Builder(builder: (_) => _getDebugTab(viewModel, controller)),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.log),
                  icon: const Icon(LucideIcons.scrollText),
                  title: const Text("Log"),
                  body: Builder(builder: (_) => _log),
                ),
                PaneItem(
                  key: ValueKey(SettingsPageKey.about),
                  icon: const Icon(LucideIcons.info),
                  title: const Text("About"),
                  body: Builder(builder: (_) => _aboutTab),
                ),
              ],
            ),
          );
        },
      ),
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

enum SettingsPageKey {

  quickSettings,

  project,
  import,
  general,
  hardware,
  output,
  ui,
  templating,
  mqtt,
  faceRecognition,

  subsystemStatus,
  stats,
  debug,
  log,
  about;

}
