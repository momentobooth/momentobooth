part of '../settings_overlay_view.dart';

Widget _getDebugTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "Debug",
    blocks: [
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
