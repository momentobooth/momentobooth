import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';
import 'package:momento_booth/views/components/imaging/live_view.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';

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

  void onCaptureFinished() {
    final image = getIt<PhotosManager>().photos.last;
    final imageData = image.data;
    uploadImage(imageData);
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
    getIt<PhotosManager>().initiateDelayedPhotoCapture(onCaptureFinished, captureDelayOverride: widget.countDown);
  }

  void capture() {
    setState(() => _showCounter = false);
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
                      onCounterFinished: capture,
                      counterStart: widget.countDown,
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
