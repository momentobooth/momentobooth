import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/hardware_control/photo_capturing/live_view_stream_snapshot_capturer.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/hardware_control/photo_capturing/sony_remote_photo_capture.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/custom_widgets/capture_counter.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view.dart';

enum FaceDetectionState { success, noFace, unknown }

class FindFaceDialog extends StatefulWidget {

  final String title;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final int countDown;

  const FindFaceDialog({
    super.key,
    required this.title,
    required this.onSuccess,
    required this.onCancel,
    this.countDown = 3,
  });

  @override
  State<FindFaceDialog> createState() => _FindFaceDialogState();

}

class _FindFaceDialogState extends State<FindFaceDialog> with Logger {

  bool _showCounter = true;
  FaceDetectionState _faceDetectionState = FaceDetectionState.unknown;
  int _numFaces = 0;

  static const flashStartDuration = Duration(milliseconds: 50);
  final PhotoCaptureMethod capturer = switch (SettingsManager.instance.settings.hardware.captureMethod) {
    CaptureMethod.sonyImagingEdgeDesktop => SonyRemotePhotoCapture(SettingsManager.instance.settings.hardware.captureLocation),
    CaptureMethod.liveViewSource => LiveViewStreamSnapshotCapturer(),
    CaptureMethod.gPhoto2 => LiveViewManager.instance.gPhoto2Camera!,
  };

  @computed
  Duration get photoDelay => Duration(seconds: widget.countDown) - capturer.captureDelay + flashStartDuration;

  Future<void> captureAndGetPhoto() async {
    Uint8List imageData;
    try {
      final image = await capturer.captureAndGetPhoto();
      imageData = image.data;
    } catch (error) {
      logWarning(error);
      final ByteData data = await rootBundle.load('assets/bitmap/capture-error.png');
      imageData = data.buffer.asUint8List();
    }
    await uploadImage(imageData);
  }

  Future<void> uploadImage(Uint8List image) async {
    logDebug("Uploading image to face detection server");
    Uri uri = Uri(host: "localhost", port: 3232, scheme: "http", path: "/upload");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes("file", image, contentType: MediaType('image', 'jpeg'), filename: "captured-imaged.jpg"));
    var response = await http.Response.fromStream(await request.send());
    setState(() {
      _faceDetectionState = switch (response.statusCode) {
        200 => FaceDetectionState.success,
        422 => FaceDetectionState.noFace,
        _ => FaceDetectionState.unknown
      };
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        _numFaces = data['num'];
      }
    });
    logDebug("Face detection state updated: $_faceDetectionState, $_numFaces");
    widget.onSuccess();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(photoDelay).then((_) => captureAndGetPhoto());
  }

  void capture() {
    setState(() => _showCounter = false);
    logDebug("Capture initiated with method $capturer");
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
                    opacity: _showCounter ? 1.0 : 0.0,
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
          icon: LucideIcons.check,
          onPressed: widget.onSuccess,
        ),
      ],
    );
  }

}
