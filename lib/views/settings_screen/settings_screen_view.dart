import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:momento_booth/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

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
                body: Builder(builder: (_) => _generalSettings),
              ),
              PaneItem(
                icon: Icon(FluentIcons.devices4),
                title: Text("Hardware"),
                body: Builder(builder: (_) => _hardwareSettings),
              ),
              PaneItem(
                icon: Icon(FluentIcons.send),
                title: Text("Output"),
                body: Builder(builder: (_) => _outputSettings),
              ),
            ],
          ),
        );
      },
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
            _getBooleanInput(
              icon: FluentIcons.favorite_star,
              title: "Display confetti 🎉",
              subtitle: "If enabled, confetti will shower the share screen!",
              value: () => viewModel.displayConfettiSetting,
              onChanged: controller.onDisplayConfettiChanged,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Hit Ctrl+F or Alt+Enter to toggle fullscreen mode."),
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Creative",
          settings: [
            _getFolderPickerCard(
              icon: FluentIcons.fabric_report_library,
              title: "Collage background templates location",
              subtitle: "Location to look for template files",
              dialogTitle: "Select templates location",
              controller: controller.templatesFolderSettingController,
              onChanged: controller.onTemplatesFolderChanged,
            ),
            _getBooleanInput(
              icon: FluentIcons.picture_center,
              title: "Treat single photo as collage",
              subtitle: "If enabled, a single picture will be processed as if it were a collage with 1 photo selected. Else the photo will be used unaltered.",
              value: () => viewModel.singlePhotoIsCollageSetting,
              onChanged: controller.onSinglePhotoIsCollageChanged,
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
          title: "Live view",
          settings: [
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Live view method",
              subtitle: "Method used for live previewing",
              items: viewModel.liveViewMethods,
              value: () => viewModel.liveViewMethodSetting,
              onChanged: controller.onLiveViewMethodChanged,
            ),
            if (viewModel.liveViewMethodSetting == LiveViewMethod.webcam)
              _webcamCard,
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Flip image",
              subtitle: "Whether the image should be flipped in none, one or both axis",
              items: viewModel.liveViewFlipImageChoices,
              value: () => viewModel.liveViewFlipImage,
              onChanged: controller.onLiveViewFlipImageChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Photo capture",
          settings: [
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Capture method",
              subtitle: "Method used for capturing final images",
              items: viewModel.captureMethods,
              value: () => viewModel.captureMethodSetting,
              onChanged: controller.onCaptureMethodChanged,
            ),
            _getFolderPickerCard(
              icon: FluentIcons.folder,
              title: "Capture location",
              subtitle: "Location to look for captured images",
              dialogTitle: "Select location to look for captured images",
              controller: controller.captureLocationController,
              onChanged: controller.onCaptureLocationChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Printing",
          settings: [
            _printerCard,
          ],
        ),
      ],
    );
  }

  FluentSettingCard get _webcamCard {
    return FluentSettingCard(
      icon: FluentIcons.camera,
      title: "Webcam",
      subtitle: "Pick the webcam to use for live view",
      child: Row(
        children: [
          Button(
            onPressed: viewModel.setWebcamList,
            child: const Text('Refresh'),
          ),
          SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 150),
            child: Observer(builder: (_) {
              return ComboBox<String>(
                items: viewModel.webcams,
                value: viewModel.liveViewWebcamId,
                onChanged: controller.onLiveViewWebcamIdChanged,
              );
            }),
          ),
        ],
      ),
    );
  }

  FluentSettingCard get _printerCard {
    return FluentSettingCard(
      icon: FluentIcons.print,
      title: "Printer",
      subtitle: "Which printer to use for printing photos",
      child: Row(
        children: [
          Button(
            onPressed: viewModel.setPrinterList,
            child: const Text('Refresh'),
          ),
          SizedBox(width: 10),
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
    );
  }

  Widget get _outputSettings {
    return FluentSettingsPage(
      title: "Output",
      blocks: [
        FluentSettingsBlock(
          title: "Local",
          settings: [
            _getFolderPickerCard(
              icon: FluentIcons.fabric_picture_library,
              title: "Local photo storage location",
              subtitle: "Location where the output images will be stored",
              dialogTitle: "Select local output storage location",
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
