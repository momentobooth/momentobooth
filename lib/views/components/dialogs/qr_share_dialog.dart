import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/components/qr_code.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class QrShareDialog extends StatelessWidget {

  final ShareDialogState state;
  final double? uploadProgress;
  final String? qrText;
  final VoidCallback onRedoUpload;
  final VoidCallback onDismiss;

  const QrShareDialog({
    super.key,
    required this.state,
    this.uploadProgress,
    this.qrText,
    required this.onRedoUpload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: localizations.qrDialogTitle,
      // SH: For my future self... The AnimatedSize will normally animate both the width and height.
      // However, it does not animate width changes due to ModelDialog's usage of IntrinsicWidth.
      body: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: switch (state) {
          ShareDialogState.uploading => _uploadingState(context),
          ShareDialogState.uploaded => _uploadedState(context),
          ShareDialogState.error => Text(localizations.qrDialogErrorMessage),
        },
      ),
      actions: switch (state) {
        ShareDialogState.uploaded => [
            PhotoBoothOutlinedButton(
              title: localizations.qrDialogExtraDownloadButton,
              icon: LucideIcons.repeat,
              onPressed: onRedoUpload,
            ),
            PhotoBoothFilledButton(
              title: localizations.genericCloseButton,
              icon: LucideIcons.check,
              onPressed: onDismiss,
            ),
          ],
        ShareDialogState.error => [
            PhotoBoothOutlinedButton(
              title: localizations.genericCancelButton,
              onPressed: onDismiss,
            ),
            PhotoBoothFilledButton(
              title: localizations.genericRetryButton,
              icon: LucideIcons.check,
              onPressed: onRedoUpload,
            ),
          ],
        _ => const [],
      },
      dialogType: switch (state) {
        ShareDialogState.error => ModalDialogType.error,
        _ => null,
      },
    );
  }

  Widget _uploadingState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return SizedBox(
      width: 300,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(value: uploadProgress),
          const SizedBox(height: 16.0),
          Text(localizations.qrDialogUploading),
        ],
      ),
    );
  }

  Widget _uploadedState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    final Color accentColor = FluentTheme.of(context).accentColor;
    final HSLColor accentColorHSL = HSLColor.fromColor(accentColor);
    final Color accentColorLight = HSLColor.fromAHSL(1, accentColorHSL.hue, accentColorHSL.saturation, 0.7).toColor();
    final Color accentColorLightest = HSLColor.fromAHSL(1, accentColorHSL.hue, accentColorHSL.saturation, 0.8).toColor();

    return SizedBox(
      width: 650,
      height: 250,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: QrCode(size: 220, data: qrText!),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/Animation - 1710968427507.json',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  height: 100,
                  frameRate: FrameRate.max,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.color(
                        // keyPath order: ['layer name', 'group name', 'shape name']
                        const ["Codigo-qr-big Outlines", "**"],
                        value: accentColorLight
                      ),
                      ValueDelegate.color(
                        const ["Codigo-qr-small Outlines", "**"],
                        value: accentColorLightest
                      ),
                      ValueDelegate.color(
                        const ["Linea Outlines", "**"],
                        value: FluentTheme.of(context).accentColor
                      ),
                    ]
                  )
                ),
                const SizedBox(height: 16.0),
                Text(
                  localizations.qrDialogInstructions,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

enum ShareDialogState {
  uploading,
  uploaded,
  error,
}

@widgetbook.UseCase(
  name: 'QR Share Dialog',
  type: QrShareDialog,
)
Widget printerIssueDialog(BuildContext context) {
  return QrShareDialog(
    state: context.knobs.list(label: 'State', initialOption: ShareDialogState.uploading, options: ShareDialogState.values),
    uploadProgress: context.knobs.double.slider(label: 'Upload Progress', initialValue: 25, max: 100, min: 0),
    qrText: context.knobs.string(label: 'QR Text', initialValue: 'https://momento.booth/123456'),
    onRedoUpload: () {},
    onDismiss: () {},
  );
}
