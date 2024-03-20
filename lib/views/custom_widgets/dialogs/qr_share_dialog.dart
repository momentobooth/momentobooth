import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/custom_widgets/qr_code.dart';
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
              icon: FontAwesomeIcons.repeat,
              onPressed: onRedoUpload,
            ),
            PhotoBoothFilledButton(
              title: localizations.genericCloseButton,
              icon: FontAwesomeIcons.check,
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
              icon: FontAwesomeIcons.check,
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

    return SizedBox(
      width: 650,
      height: 250,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Center(
              child: QrCode(size: 200, data: qrText!),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/Animation - 1710968427507.json',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  height: 100,
                  frameRate: FrameRate.max,
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
