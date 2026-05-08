import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/src/rust/utils/ffsend_client.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/speech_phrases.dart';
import 'package:momento_booth/views/base/has_actions_mixin.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/components/qr_code.dart';
import 'package:path/path.dart' as path;
// import 'package:widgetbook/widgetbook.dart';
// import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class QrShareDialog extends StatefulWidget {

  final File file;
  final VoidCallback onDismiss;
  final Object actionsToken;

  const QrShareDialog({
    super.key,
    required this.file,
    required this.onDismiss,
    required this.actionsToken,
  });

  @override
  State<QrShareDialog> createState() => _QrShareDialogState();
}

class _QrShareDialogState extends State<QrShareDialog> with Logger, HasActionsMixin {
  ShareDialogState _state = ShareDialogState.uploading;
  double? uploadProgress;
  String? qrText;

  set state(ShareDialogState newState) {
    _state = newState;
    pushActions();
  }

  ShareDialogState get state => _state;

  @override
  String get scopeName => "QR Share Dialog";

  @override
  void initState() {
    super.initState();
    uploadPhotoToSend();
  }

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
              onPressed: uploadPhotoToSend,
            ),
            PhotoBoothFilledButton(
              title: localizations.genericCloseButton,
              icon: LucideIcons.check,
              onPressed: widget.onDismiss,
            ),
          ],
        ShareDialogState.error => [
            PhotoBoothOutlinedButton(
              title: localizations.genericCancelButton,
              onPressed: widget.onDismiss,
            ),
            PhotoBoothFilledButton(
              title: localizations.genericRetryButton,
              icon: LucideIcons.check,
              onPressed: uploadPhotoToSend,
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

  Future<void> uploadPhotoToSend() async {
    logDebug("Uploading ${widget.file.path}");
    setState(() {
      state = ShareDialogState.uploading;
      uploadProgress = 0.0;
    });
    String ffSendUrl = getIt<SettingsManager>().settings.output.firefoxSendServerUrl;

    String basename = path.basename(widget.file.path);
    Stream<FfSendTransferProgress> stream = ffsendUploadFile(
      filePath: widget.file.path,
      hostUrl: ffSendUrl,
      downloadFilename: basename,
      controlCommandTimeout: getIt<SettingsManager>().settings.output.firefoxSendControlCommandTimeout,
      transferTimeout: getIt<SettingsManager>().settings.output.firefoxSendTransferTimeout,
    );

    uploadProgress = 0.0;

    stream.listen((event) async {
      if (event.isFinished) {
        logDebug("Upload complete: ${event.downloadUrl}");

        await Future.delayed(const Duration(milliseconds: 500));
        qrText = event.downloadUrl;
        uploadProgress = null;

        getIt<StatsManager>().addUploadedPhoto();
        setState(() => state = ShareDialogState.uploaded);
      } else {
        logDebug("Uploading: ${event.transferredBytes}/${event.totalBytes} bytes");
        setState(() => uploadProgress = event.transferredBytes / (event.totalBytes ?? 0));
      }
    }).onError((x) async {
      logError("Upload failed, file path: ${widget.file.path}", x);
      await Future.delayed(const Duration(seconds: 1));
      setState(() => uploadProgress = null);
      setState(() => state = ShareDialogState.error);
    });
  }

  @override
  List<AppAction> get actions => switch (state) {
    // These are actually the same actions, but with different names
    ShareDialogState.uploaded => [
        AppAction(
          name: "redo_upload",
          callback: (_, response) { uploadPhotoToSend(); response(true, "Redo upload button pressed"); },
          title: "Redo Upload",
          description: "Start the upload process again to get a new QR code",
          examples: [
            "redo upload",
            "upload again",
            "upload another one",
            "get me a new QR code",
          ],
        ),
        AppAction(
          name: "close",
          callback: (_, response) { widget.onDismiss(); response(true, "Close button pressed"); },
          title: "Close",
          description: "Close the QR sharing dialog.",
          examples: cancelPhrases
        ),
      ],
    ShareDialogState.error => [
        AppAction(
          name: "cancel",
          callback: (_, response) { widget.onDismiss(); response(true, "Cancel button pressed"); },
          title: "Cancel",
          description: "Cancel the upload process.",
          examples: cancelPhrases
        ),
        AppAction(
          name: "retry_upload",
          callback: (_, response) { uploadPhotoToSend(); response(true, "Retry upload button pressed"); },
          title: "Retry Upload",
          description: "After an error has occurred, this will try uploading the photo again.",
          examples: [
            "try again",
            "retry upload",
            "try uploading again",
          ],
        ),
      ],
    _ => [],
  };
}

enum ShareDialogState {
  uploading,
  uploaded,
  error,
}

// Todo: figure out how to re-enable this now that the widget is stateful.
/*@UseCase(name: 'QR Share Dialog', type: QrShareDialog)
Widget qrShareDialog(BuildContext context) {
  return QrShareDialog(
    state: context.knobs.object.dropdown(label: 'State', initialOption: ShareDialogState.uploading, options: ShareDialogState.values),
    uploadProgress: context.knobs.double.slider(label: 'Upload Progress', initialValue: 25, max: 100, min: 0),
    qrText: context.knobs.string(label: 'QR Text', initialValue: 'https://momento.booth/123456'),
    onRedoUpload: () {},
    onDismiss: () {},
  );
}*/
