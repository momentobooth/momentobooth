part of '../settings_overlay_view.dart';

Widget _getHardwareSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsListPage(
    title: "Hardware",
    blocks: [
      _getGeneralBlock(viewModel, controller),
      _getImagingBlock(viewModel, controller),
      _getPrintingBlock(viewModel, controller),
      Observer(builder: (_) =>
        switch(viewModel.printingImplementationSetting) {
          PrintingImplementation.none => const SizedBox(),
          PrintingImplementation.flutterPrinting => _getFlutterPrintingBlock(viewModel, controller),
          PrintingImplementation.cups => _getCupsBlock(viewModel, controller),
        }
      ),
    ],
  );
}

Widget _getGeneralBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsSection(
    title: "General",
    settings: [
      SettingsComboBoxTile(
        icon: LucideIcons.camera,
        title: "Rotate image",
        subtitle: "Whether the live view and captures will be rotated 90, 180 or 270 degrees clockwise.",
        items: viewModel.liveViewAndCaptureRotateOptions,
        value: () => viewModel.liveViewAndCaptureRotateSetting,
        onChanged: controller.onLiveViewAndCaptureRotateChanged,
      ),
      SettingsComboBoxTile(
        icon: LucideIcons.camera,
        title: "Flip image – Live View",
        subtitle: "Whether the live view image will be flipped horizontally or vertically.",
        items: viewModel.flipOptions,
        value: () => viewModel.liveViewFlipSetting,
        onChanged: controller.onLiveViewFlipChanged,
      ),
      SettingsComboBoxTile(
        icon: LucideIcons.camera,
        title: "Flip image – Capture",
        subtitle: "Whether the captured image will be flipped horizontally or vertically.",
        items: viewModel.flipOptions,
        value: () => viewModel.captureFlipSetting,
        onChanged: controller.onCaptureFlipChanged,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.ratio,
        title: "Aspect ratio",
        subtitle: 'The aspect ratio to which live view and captures are cropped.',
        value: () => viewModel.liveViewAndCaptureAspectRatioSetting,
        onFinishedEditing: controller.onLiveViewAndCaptureAspectRatioChanged,
        smallChange: 0.1,
        leading: Observer(
          builder: (_) => AspectRatioPreview(aspectRatio: viewModel.liveViewAndCaptureAspectRatioSetting),
        ),
      ),
    ],
  );
}

Widget _getImagingBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return Observer(
    builder: (context) {
      return SettingsSection(
        title: "Live view and capture",
        settings: [
          _getImagingOptionsCard(viewModel, controller),
          SettingsTile(
            icon: LucideIcons.projector,
            title: 'Live view preview',
            subtitle: 'Preview of the raw image as captured from the chosen imaging device.',
            setting: SizedBox(
              height: 100,
              child: getIt<LiveViewManager>().subsystemStatus is SubsystemStatusOk
                  ? LiveView(fit: BoxFit.contain, applyPostProcessing: false)
                  : Placeholder(fallbackWidth: 150),
            ),
          ),
          if (viewModel.captureMethodSetting != CaptureMethod.sonyImagingEdgeDesktop)
            SettingsToggleTile(
              icon: LucideIcons.hardDriveDownload,
              title: "Save captures to disk",
              subtitle: "Whether to save captures to disk.",
              value: () => viewModel.saveCapturesToDiskSetting,
              onChanged: controller.onSaveCapturesToDiskChanged,
            ),
          if (viewModel.imagingMethod == ImagingMethod.custom) ...[
            SettingsComboBoxTile(
              icon: LucideIcons.camera,
              title: "Live view method",
              subtitle: "Method used for live previewing",
              items: viewModel.liveViewMethods,
              value: () => viewModel.liveViewMethodSetting,
              onChanged: controller.onLiveViewMethodChanged,
            ),
            if (viewModel.liveViewMethodSetting == LiveViewMethod.webcam)
              _getWebcamCard(viewModel, controller),
            SettingsComboBoxTile(
              icon: LucideIcons.camera,
              title: "Capture method",
              subtitle: "Method used for capturing final images",
              items: viewModel.captureMethods,
              value: () => viewModel.captureMethodSetting,
              onChanged: controller.onCaptureMethodChanged,
            ),
            if (viewModel.captureMethodSetting == CaptureMethod.sonyImagingEdgeDesktop)
              SettingsNumberEditTile(
                icon: LucideIcons.timer,
                title: "Capture delay for Sony camera",
                subtitle: "Delay in [ms]. Sensible values are between 165 (manual focus) and 500 ms.",
                value: () => viewModel.captureDelaySonySetting,
                onFinishedEditing: controller.onCaptureDelaySonyChanged,
              ),
            if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2 || viewModel.liveViewMethodSetting == LiveViewMethod.gphoto2)
              _gPhoto2CamerasCard(viewModel, controller),
          ],
          if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2 || viewModel.liveViewMethodSetting == LiveViewMethod.gphoto2)
            SettingsComboBoxTile(
              icon: LucideIcons.camera,
              title: "Use special handling for camera",
              subtitle: "Kind of special handling used for the camera. Pick \"Nikon DSLR\" for cameras like the D-series. The \"None\" might work for most mirrorless camera as they are always in live view mode.",
              items: viewModel.gPhoto2SpecialHandlingOptions,
              value: () => viewModel.gPhoto2SpecialHandling,
              onChanged: controller.onGPhoto2SpecialHandlingChanged,
            ),
          if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2)
            SettingsToggleTile(
              icon: LucideIcons.camera,
              title: "Download extra files (e.g. RAW) from camera",
              subtitle: "Whether to download extra files from the camera. This is useful for cameras that can create RAW files.",
              value: () => viewModel.gPhoto2DownloadExtraFilesSetting,
              onChanged: controller.onGPhoto2DownloadExtraFilesChanged,
            ),
          if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2)
            SettingsTextEditTile(
              icon: LucideIcons.memoryStick,
              title: "Camera capture target",
              subtitle: "Sets the camera's 'capturetarget'. When unsure, leave empty as it could cause capture issues. Values can be found in the libgphoto2 source code.",
              controller: controller.gPhoto2CaptureTargetController,
              onFinishedEditing: controller.onGPhoto2CaptureTargetChanged,
            ),
          if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2)
            SettingsNumberEditTile(
              icon: LucideIcons.camera,
              title: "Auto focus before capture",
              subtitle: "Time to wait for the camera to focus before capturing the image. This could be useful to improve capture speed in some cases (e.g. bad light, camera being slow with focusing). Might require the 'Special handling' setting set for some vendors. Also it might not work on some camera models. Set to 0 to disable.",
              value: () => viewModel.gPhoto2AutoFocusMsBeforeCaptureSetting,
              onFinishedEditing: controller.onGPhoto2AutoFocusMsBeforeCaptureChanged,
            ),
          if (viewModel.captureMethodSetting == CaptureMethod.gPhoto2)
            SettingsNumberEditTile(
              icon: LucideIcons.timer,
              title: "Capture delay for gPhoto2 camera.",
              subtitle: "Delay in [ms].",
              value: () => viewModel.captureDelayGPhoto2Setting,
              onFinishedEditing: controller.onCaptureDelayGPhoto2Changed,
            ),
          if (viewModel.captureMethodSetting == CaptureMethod.sonyImagingEdgeDesktop)
            SettingsFolderSelectTile(
              icon: LucideIcons.folder,
              title: "Capture location",
              subtitle: "Location to look for captured images.",
              controller: controller.captureLocationController,
              onChanged: controller.onCaptureLocationChanged,
            ),
        ],
      );
    }
  );
}

Widget _getPrintingBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsSection(
    title: "Printing",
    settings: [
      SettingsComboBoxTile(
        icon: LucideIcons.printer,
        title: "Print method",
        subtitle: "Method used for printing photos",
        items: viewModel.printingImplementations,
        value: () => viewModel.printingImplementationSetting,
        onChanged: controller.onPrintingImplementationChanged,
      ),
      _printerMargins(viewModel, controller),
      SettingsNumberEditTile(
        icon: LucideIcons.printerCheck,
        title: "Queue warning threshold",
        subtitle: "Number of photos in the OS's printer queue before a warning is shown (Windows only for now).",
        value: () => viewModel.printerQueueWarningThresholdSetting,
        onFinishedEditing: controller.onPrinterQueueWarningThresholdChanged,
      ),
    ],
  );
}

Widget _getCupsBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsSection(
    title: "CUPS",
    settings: [
      SettingsTextEditTile(
        icon: LucideIcons.server,
        title: "CUPS URI",
        subtitle: "The URI of the CUPS server",
        controller: controller.cupsUriController,
        onFinishedEditing: controller.onCupsUriChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.server,
        title: "Ignore TLS errors",
        subtitle: "Whether to ignore TLS errors when connecting to the CUPS server. This is useful for self-signed certificates which are used by default by the CUPS service.",
        value: () => viewModel.cupsIgnoreTlsErrors,
        onChanged: controller.onCupsIgnoreTlsErrorsChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.user,
        title: "CUPS username",
        subtitle: "The username for the CUPS server",
        controller: controller.cupsUsernameController,
        onFinishedEditing: controller.onCupsUsernameChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.squareAsterisk,
        title: "CUPS password",
        subtitle: "The password for the CUPS server",
        controller: controller.cupsPasswordController,
        onFinishedEditing: controller.onCupsPasswordChanged,
      ),
      Observer(builder: (_) => _cupsPageSizeCard(viewModel, controller, "Media size: Normal", LucideIcons.square, PrintSize.normal, viewModel.mediaSizeNormal)),
      Observer(builder: (_) => _cupsPageSizeCard(viewModel, controller, "Media size: Split", LucideIcons.rows2, PrintSize.split, viewModel.mediaSizeSplit)),
      Observer(builder: (_) => _cupsPageSizeCard(viewModel, controller, "Media size: Small", LucideIcons.grid2x2, PrintSize.small, viewModel.mediaSizeSmall)),
      Observer(builder: (_) => _gridPrint(viewModel, controller, "small", PrintSize.small, viewModel.gridSmall)),
      Observer(builder: (_) => _cupsPageSizeCard(viewModel, controller, "Media size: Tiny", LucideIcons.grid3x3, PrintSize.tiny, viewModel.mediaSizeTiny)),
      Observer(builder: (_) => _gridPrint(viewModel, controller, "tiny", PrintSize.tiny, viewModel.gridTiny)),
      Observer(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i <= viewModel.cupsPrinterQueuesSetting.length; i++)
              _cupsQueuesCard(viewModel, controller, "Printer ${i + 1}", i),
          ],
        ),
      ),
    ],
  );
}

Widget _getFlutterPrintingBlock(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsSection(
    title: "Flutter Printing",
    settings: [
      Observer(builder: (context) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i <= viewModel.flutterPrintingPrinterNamesSetting.length; i++)
              _printerCard(viewModel, controller, "Printer ${i+1}", i),
          ],
        ),
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.moveVertical,
        title: "Page height",
        subtitle: 'Page format height used for printing [mm]',
        value: () => viewModel.pageHeightSetting,
        onFinishedEditing: controller.onPageHeightChanged,
        smallChange: 0.1,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.moveHorizontal,
        title: "Page width",
        subtitle: 'Page format width used for printing [mm]',
        value: () => viewModel.pageWidthSetting,
        onFinishedEditing: controller.onPageWidthChanged,
        smallChange: 0.1,
      ),
      SettingsToggleTile(
        icon: LucideIcons.settings,
        title: "usePrinterSettings for printing",
        subtitle: "Control the usePrinterSettings property of the Flutter printing library.",
        value: () => viewModel.usePrinterSettingsSetting,
        onChanged: controller.onUsePrinterSettingsChanged,
      ),
    ],
  );
}

SettingsTile _printerMargins(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  const double numberWidth = 100;
  const double padding = 10;
  return SettingsTile(
    icon: LucideIcons.file,
    title: "Page margins used for printing",
    subtitle: "Some printers cut off some part of the image. Use this to compensate.\nOrder: top, right, bottom, left [mm]",
    setting: Row(
      children: [
        SizedBox(
          width: numberWidth,
          child: Observer(builder: (_) {
            return NumberBox<double>(
              value: viewModel.printerMarginTopSetting,
              onChanged: controller.onPrinterMarginTopChanged,
              smallChange: 0.1,
            );
          }),
        ),
        const SizedBox(width: padding),
        SizedBox(
          width: numberWidth,
          child: Observer(builder: (_) {
            return NumberBox<double>(
              value: viewModel.printerMarginRightSetting,
              onChanged: controller.onPrinterMarginRightChanged,
              smallChange: 0.1,
            );
          }),
        ),
        const SizedBox(width: padding),
        SizedBox(
          width: numberWidth,
          child: Observer(builder: (_) {
            return NumberBox<double>(
              value: viewModel.printerMarginBottomSetting,
              onChanged: controller.onPrinterMarginBottomChanged,
              smallChange: 0.1,
            );
          }),
        ),
        const SizedBox(width: padding),
        SizedBox(
          width: numberWidth,
          child: Observer(builder: (_) {
            return NumberBox<double>(
              value: viewModel.printerMarginLeftSetting,
              onChanged: controller.onPrinterMarginLeftChanged,
              smallChange: 0.1,
            );
          }),
        ),
      ],
    ),
  );
}

SettingsTile _getImagingOptionsCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsTile(
    icon: LucideIcons.camera,
    title: "Imaging device",
    subtitle: "Pick the device to use for live view and capture",
    // The tile uses a row internally with an Expanded around the information, so we use an Expanded here too to create a reactive layout.
    setting: Expanded(
      flex: 2,
      child: Observer(
        builder: (_) => _getImagingOptions(viewModel, controller)
      ),
    ),
  );
}

Widget _getImagingOptions(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.end,
    children: [
      _getImagingButton(LucideIcons.rotateCcw, 'Refresh', 'Refresh all devices', false, viewModel.setImagingDeviceList),
      for (final webcam in viewModel.webcamList) ...[
        _getImagingButton(
          LucideIcons.webcam,
          'Webcam',
          webcam.friendlyName,
          viewModel.imagingMethod == ImagingMethod.webcam && viewModel.liveViewWebcamId == webcam.friendlyName,
          () => controller.setImagingWebcam(webcam),
        )
      ],
      for (final camera in viewModel.gPhoto2CameraList) ...[
        _getImagingButton(
          LucideIcons.camera,
          'Camera',
          '${camera.model}\nat ${camera.port}',
          viewModel.imagingMethod == ImagingMethod.gphoto2 && viewModel.gPhoto2CameraId == GPhoto2Camera.fromCameraInfo(camera).id,
          () => controller.setImagingGPhoto2(camera),
        )
      ],
      _getImagingButton(
        LucideIcons.audioWaveform,
        "Static noise", "Debug option",
        viewModel.imagingMethod == ImagingMethod.debugNoise,
        () => controller.setImagingStaticNoise()
      ),
      _getImagingButton(
        LucideIcons.image,
        "Static image",
        "Debug option",
        viewModel.imagingMethod == ImagingMethod.debugStaticImage,
        () => controller.setImagingStaticImage()
      ),
      _getImagingButton(
        LucideIcons.wrench,
        "Custom",
        "Select options yourself",
        viewModel.imagingMethod == ImagingMethod.custom,
        () => controller.onCustomImagingOptionsSelected(),
      ),
    ],
  );
}

Widget _getImagingButton(IconData icon, String title, String subtitle, bool isSelected, VoidCallback onPressed) {
  return ToggleButton(
    checked: isSelected,
    onChanged: (v) => onPressed(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    )
  );
}

SettingsTile _getWebcamCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsTile(
    icon: LucideIcons.camera,
    title: "Webcam",
    subtitle: "Pick the webcam to use for live view",
    setting: Row(
      children: [
        Button(
          onPressed: viewModel.setWebcamList,
          child: const Text('Refresh'),
        ),
        const SizedBox(width: 10),
        Observer(builder: (_) {
          return ComboBox<String>(
            items: viewModel.webcamComboBoxItems,
            value: viewModel.liveViewWebcamId,
            onChanged: controller.onLiveViewWebcamIdChanged,
            disabledPlaceholder: Text('<No options>'),
          );
        }),
      ],
    ),
  );
}

SettingsTile _gPhoto2CamerasCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsTile(
    icon: LucideIcons.camera,
    title: "Camera",
    subtitle: "Pick the camera to use for capturing still frames",
    setting: Row(
      children: [
        Button(
          onPressed: viewModel.setCameraList,
          child: const Text('Refresh'),
        ),
        const SizedBox(width: 10),
        Observer(builder: (_) {
          return ComboBox<String>(
            items: viewModel.gPhoto2CameraComboBoxItems,
            value: viewModel.gPhoto2CameraId,
            onChanged: controller.onGPhoto2CameraIdChanged,
            disabledPlaceholder: Text('<No options>'),
          );
        }),
      ],
    ),
  );
}

SettingsTile _printerCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, String title, int index) {
  return SettingsTile(
    icon: LucideIcons.printerCheck,
    title: title,
    subtitle: "Which printer(s) to use for printing photos",
    setting: Row(
      children: [
        Button(
          onPressed: viewModel.setFlutterPrintingQueueList,
          child: const Text('Refresh'),
        ),
        const SizedBox(width: 10),
        Observer(builder: (_) {
          return ComboBox<String>(
            items: viewModel.flutterPrintingQueues,
            value: index < viewModel.flutterPrintingPrinterNamesSetting.length ? viewModel.flutterPrintingPrinterNamesSetting[index] : viewModel.unusedPrinterValue,
            onChanged: (name) => controller.onFlutterPrintingPrinterChanged(name, index),
            disabledPlaceholder: Text('<No options>'),
          );
        }),
      ],
    ),
  );
}

SettingsTile _cupsQueuesCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, String title, int index) {
  return SettingsTile(
    icon: LucideIcons.printerCheck,
    title: title,
    subtitle: "Which printer(s) to use for printing photos",
    setting: Row(
      children: [
        Button(
          onPressed: viewModel.setCupsQueueList,
          child: const Text('Refresh'),
        ),
        const SizedBox(width: 10),
        Observer(builder: (_) {
          return ComboBox<String>(
            items: viewModel.cupsQueues,
            value: index < viewModel.cupsPrinterQueuesSetting.length ? viewModel.cupsPrinterQueuesSetting[index] : viewModel.unusedPrinterValue,
            onChanged: (name) => controller.onCupsPrinterQueuesQueueChanged(name, index),
            disabledPlaceholder: Text('<No options>'),
          );
        }),
      ],
    ),
  );
}

SettingsTile _cupsPageSizeCard(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, String title, IconData icon, PrintSize size, MediaSettings currentSettings) {
  return SettingsTile(
    icon: icon,
    title: title,
    subtitle: size.name,
    setting: ComboBox<String>(
      items: viewModel.cupsPaperSizes,
      value: currentSettings.mediaSizeString,
      onChanged: (value) => controller.onCupsPageSizeChanged(value, size),
      disabledPlaceholder: Text('<No options>'),
    ),
  );
}

SettingsTile _gridPrint(SettingsOverlayViewModel viewModel, SettingsOverlayController controller, String sizeName, PrintSize size, GridSettings grid) {
  const double numberWidth = 100;
  const double padding = 10;
  return SettingsTile(
    icon: LucideIcons.layoutGrid,
    title: "Grid for $sizeName print",
    subtitle: "Set what grid to create for creating $sizeName prints. A grid of X by Y images is generated.\nOrder: X, Y, rotate images.",
    setting: Row(
      children: [
        SizedBox(
          width: numberWidth,
          child: NumberBox<int>(
            value: grid.x,
            onChanged: (value) => controller.onCupsGridXChanged(value, size),
          ),
        ),
        const SizedBox(width: padding),
        SizedBox(
          width: numberWidth,
          child: NumberBox<int>(
            value: grid.y,
            onChanged: (value) => controller.onCupsGridYChanged(value, size),
          ),
        ),
        const SizedBox(width: padding),
        ToggleSwitch(
          checked: grid.rotate,
          onChanged: (value)  => controller.onCupsGridRotateChanged(value, size),
        ),

      ],
    ),
  );
}
