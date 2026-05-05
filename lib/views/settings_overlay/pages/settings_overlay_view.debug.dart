part of '../settings_overlay_view.dart';

Widget _getDebugTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsListPage(
    title: "Debug",
    blocks: [
      SettingsSection(
        title: "Photos and capture",
        settings: [
          Observer(
            builder: (context) => SettingsTextDisplayTile(
              icon: LucideIcons.hash,
              title: "Photos in memory",
              subtitle: "The number of photos stored in memory in the PhotosManager",
              text: getIt<PhotosManager>().photos.length.toString(),
            ),
          ),
          Observer(
            builder: (context) => Row(
              spacing: 8.0,
              children: [
                for (int i = 0; i < getIt<PhotosManager>().photos.length; i++)
                  SizedBox.square(
                    dimension: 100,
                    child: ImageWithLoaderFallback.memory(getIt<PhotosManager>().photos[i].data, onImageDecoded: (_) => {})
                  )
              ],
            )
          ),
          SettingsActionTile(
            icon: LucideIcons.camera,
            title: "Capture photo",
            subtitle: "Trigger a photo capture",
            buttonText: "Trigger capture",
            onPressed: controller.onTriggerCapturePressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.trash,
            title: "Clear photos",
            subtitle: "Clear the photos stored in memory",
            buttonText: "Clear photos",
            onPressed: controller.onPhotosClearPressed,
          ),
        ],
      ),
      SettingsSection(
        title: "Actions - General",
        settings: [
          SettingsActionTile(
            icon: LucideIcons.play,
            title: "Play audio sample",
            subtitle: "Play a sample mp3 file, to verify whether audio file playback is working.",
            buttonText: "Audio test",
            onPressed: controller.onPlayAudioSamplePressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.mailWarning,
            title: "Report fake error",
            subtitle: "Test whether error reporting (to Sentry) works",
            buttonText: "Report Fake Error",
            onPressed: () => throw Exception("This is a fake error to test error reporting"),
          ),
        ],
      ),
      SettingsSection(
        title: "Actions - gPhoto2",
        settings: [
          SettingsActionTile(
            icon: LucideIcons.video,
            title: "Start video recording",
            subtitle: "Start a video recording using gPhoto2",
            buttonText: "Start recording",
            onPressed: controller.onStartVideoRecordingPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.videoOff,
            title: "Stop video recording",
            subtitle: "Stop a video recording using gPhoto2",
            buttonText: "Stop recording",
            onPressed: controller.onStopVideoRecordingPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.folder,
            title: "Get camera files",
            subtitle: "Retrieve a list of files on the camera and display it in the console.",
            buttonText: "Get filelist",
            onPressed: controller.onGetCameraFilesPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.settings,
            title: "Get camera config",
            subtitle: "Retrieve the camera's full config as a Dart object and display it in the console.",
            buttonText: "Get config",
            onPressed: controller.onGetCameraConfigPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.camera,
            title: "Copy camera info to clipboard",
            subtitle: "Copy camera info (e.g. capabilities, connection info, config info) in JSON format to the clipboard",
            buttonText: "Copy to clipboard",
            onPressed: controller.onCopyCameraInfoToClipboardPressed,
          ),
          SettingsTile(
            icon: LucideIcons.textCursorInput,
            title: "Set text config",
            subtitle: "Set a text-type camera setting by key name.",
            setting: Row(
              spacing: 8,
              children: [
                SizedBox(width: 160, child: TextBox(placeholder: "Key", controller: controller.debugConfigTextKeyController)),
                SizedBox(width: 160, child: TextBox(placeholder: "Value", controller: controller.debugConfigTextValueController)),
                Button(onPressed: controller.onSetConfigTextPressed, child: const Text("Set")),
              ],
            ),
          ),
          SettingsTile(
            icon: LucideIcons.toggleRight,
            title: "Set toggle config",
            subtitle: "Set a toggle-type camera setting by key name.",
            setting: Row(
              spacing: 8,
              children: [
                SizedBox(width: 160, child: TextBox(placeholder: "Key", controller: controller.debugConfigToggleKeyController)),
                Button(onPressed: controller.onEnableConfigTogglePressed, child: const Text("Enable")),
                Button(onPressed: controller.onDisableConfigTogglePressed, child: const Text("Disable")),
              ],
            ),
          ),
          SettingsTile(
            icon: LucideIcons.listChecks,
            title: "Set radio config",
            subtitle: "Set a radio/choice-type camera setting by key name.",
            setting: Row(
              spacing: 8,
              children: [
                SizedBox(width: 160, child: TextBox(placeholder: "Key", controller: controller.debugConfigRadioKeyController)),
                SizedBox(width: 160, child: TextBox(placeholder: "Value", controller: controller.debugConfigRadioValueController)),
                Button(onPressed: controller.onSetConfigRadioPressed, child: const Text("Set")),
              ],
            ),
          ),
          SettingsTile(
            icon: LucideIcons.slidersHorizontal,
            title: "Set range config",
            subtitle: "Set a range-type camera setting by key name.",
            setting: Row(
              spacing: 8,
              children: [
                SizedBox(width: 160, child: TextBox(placeholder: "Key", controller: controller.debugConfigRangeKeyController)),
                SizedBox(width: 120, child: TextBox(placeholder: "Value", controller: controller.debugConfigRangeValueController)),
                Button(onPressed: controller.onSetConfigRangePressed, child: const Text("Set")),
              ],
            ),
          ),
        ],
      ),
      SettingsSection(
        title: "Logging",
        settings: [
          SettingsToggleTile(
            icon: LucideIcons.logs,
            title: "Enable extensive print job logging",
            subtitle: "Store every print job and meta data (e.g. requested paper size) in folder named 'PrintJobs' inside the output folder.",
            value: () => viewModel.enableExtensivePrintJobLog,
            onChanged: controller.onEnableExtensivePrintJobLogChanged,
          ),
        ],
      ),
      SettingsSection(
        title: "Performance",
        settings: [
          SettingsToggleTile(
            icon: LucideIcons.monitorCog,
            title: "Show FPS count",
            subtitle: "Show the FPS count in the upper right corner.",
            value: () => viewModel.debugShowFpsCounter,
            onChanged: controller.onDebugShowFpsCounterChanged,
          ),
        ],
      ),
      SettingsSection(
        title: "UI",
        settings: [
          SettingsComboBoxTile<ColorVisionDeficiency?>(
            icon: LucideIcons.eye,
            title: "Simulate Color Vision Deficiency",
            subtitle: "Simulate protanomaly, deuteranomaly or tritanomaly.",
            value: () => viewModel.simulateCvd,
            onChanged: controller.onSimulateCvdChanged,
            items: ColorVisionDeficiency.asComboBoxItems(),
          ),
          SettingsComboBoxTile<int>(
            icon: LucideIcons.eye,
            title: "Color Vision Deficiency simulation severity",
            subtitle: "This option only works if the above option is set to anything other than 'none'.",
            value: () => viewModel.simulateCvdSeverity,
            onChanged: controller.onSimulateCvdSeverityChanged,
            items: List.generate(10, (i) => ComboBoxItem(value: i, child: Text('${(i + 1) * 10}%'))),
          ),
        ],
      ),
    ],
  );
}
