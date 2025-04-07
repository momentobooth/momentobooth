part of '../settings_overlay_view.dart';

Widget _getDebugTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
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
                    child: ImageWithLoaderFallback.memory(getIt<PhotosManager>().photos[i].data, onImageDecoded: () => {})
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
        title: "Actions",
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
          SettingsActionTile(
            icon: LucideIcons.mailWarning,
            title: "Print test to receipt printer",
            subtitle: "Test whether printing to the receipt printer works",
            buttonText: "Initiate test print",
            onPressed: () async {
              ByteData imageData = await rootBundle.load('assets/bitmap/placeholder.png');
              await printReceipt(
                receipt: Receipt(
                  commands: [
                    ReceiptPrinterCommand.printImage(imageData.buffer.asUint8List()),
                    ReceiptPrinterCommand.feed(),
                    ReceiptPrinterCommand.cut(),
                  ],
                ),
                printerUsbVid: 0x0AA7,
                printerUsbPid: 0x0304,
                printingWidth: 576,
              );
            },
          ),
        ],
      ),
      SettingsSection(
        title: "Debug settings",
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
    ],
  );
}
