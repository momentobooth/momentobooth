import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/custom_widgets/capture_counter.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view.dart';

class FindFaceDialog extends StatefulWidget {

  final String title;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;
  final int countDown;

  FindFaceDialog({
    super.key,
    required this.title,
    required this.onDismiss,
    required this.onCancel,
    this.countDown = 3
  });

  @override
  State<FindFaceDialog> createState() => _FindFaceDialogState();
}

class _FindFaceDialogState extends State<FindFaceDialog> with UiLoggy {
  bool showCounter = true;
  bool captureComplete = false;

  static const flashStartDuration = Duration(milliseconds: 50);
  final PhotoCaptureMethod capturer = switch (SettingsManager.instance.settings.hardware.captureMethod) {
    CaptureMethod.sonyImagingEdgeDesktop => SonyRemotePhotoCapture(SettingsManager.instance.settings.hardware.captureLocation),
    CaptureMethod.liveViewSource => LiveViewStreamSnapshotCapturer(),
    CaptureMethod.gPhoto2 => LiveViewManager.instance.gPhoto2Camera!,
  } as PhotoCaptureMethod;
  @computed
  Duration get photoDelay => Duration(seconds: widget.countDown) - capturer.captureDelay + flashStartDuration;

  Future<void> captureAndGetPhoto() async {
    try {
      final image = await capturer.captureAndGetPhoto();
      PhotosManager.instance.photos.add(image);
      PhotosManager.instance.outputImage = image.data;
    } catch (error) {
      loggy.warning(error);
      final errorFile = File('assets/bitmap/capture-error.png');
      PhotosManager.instance.outputImage = await errorFile.readAsBytes();
    } finally {
      captureComplete = true;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(photoDelay).then((_) => captureAndGetPhoto());
  }

  void capture() {
    setState(() {
      showCounter = false;
    });
    print("Capture");
    print("Method = ${capturer}");
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return ModalDialog(
      title: widget.title,
      body: SizedBox(
        width: 700,
        child: Stack(
          children: [
            const SizedBox(
              width: 700,
              child: LiveView(
                fit: BoxFit.contain,
                blur: false,
              ),
            ),
            SizedBox(
              height: 467,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 50),
                    opacity: showCounter ? 1.0 : 0.0,
                    child: CaptureCounter(
                      onCounterFinished: capture, counterStart: widget.countDown,
                    ),
                  )
                ),
              ),
            ),
          ]
        ),
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: localizations.genericCancelButton,
          onPressed: widget.onCancel,
        ),
        PhotoBoothFilledButton(
          title: localizations.genericCloseButton,
          icon: FontAwesomeIcons.check,
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }
}
