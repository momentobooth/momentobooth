import 'dart:io';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'share_screen_view_model.g.dart';

class ShareScreenViewModel = ShareScreenViewModelBase with _$ShareScreenViewModel;

abstract class ShareScreenViewModelBase extends ScreenViewModelBase with Store, UiLoggy {

  ShareScreenViewModelBase({
    required super.contextAccessor,
  });

  bool get displayConfetti => SettingsManager.instance.settings.ui.displayConfetti;
  late final ConfettiController confettiController = ConfettiController(duration: const Duration(milliseconds: 100))..play();

  Uint8List get outputImage => PhotosManager.instance.outputImage!;

  @observable
  late String printText = localizations.genericPrintButton;

  @observable
  bool printEnabled = true;

  @readonly
  double? _uploadProgress;

  @readonly
  bool _uploadFailed = false;

  @readonly
  String? _qrUrl;

  @readonly
  File? _file;

  String get ffSendUrl => SettingsManager.instance.settings.output.firefoxSendServerUrl;
  CaptureMode get captureMode => PhotosManager.instance.captureMode;
  String get backText => captureMode == CaptureMode.single ? localizations.shareScreenRetakeButton : localizations.shareScreenChangeButton;

  Future<void> uploadPhotoToSend() async {
    _file ??= await PhotosManager.instance.getOutputImageAsTempFile();
    final ext = SettingsManager.instance.settings.output.exportFormat.name.toLowerCase();

    loggy.debug("Uploading ${_file!.path}");
    var stream = ffsendUploadFile(filePath: _file!.path, hostUrl: ffSendUrl, downloadFilename: "MomentoBooth image.$ext");

    _uploadProgress = 0.0;
    _uploadFailed = false;

    stream.listen((event) async {
      if (event.isFinished) {
        loggy.debug("Upload complete: ${event.downloadUrl}");

        await Future.delayed(const Duration(milliseconds: 500));
        _uploadProgress = null;
        _qrUrl = event.downloadUrl;

        StatsManager.instance.addUploadedPhoto();
      } else {
        loggy.debug("Uploading: ${event.transferredBytes}/${event.totalBytes} bytes");
        _uploadProgress = event.transferredBytes / (event.totalBytes ?? 0);
      }
    }).onError((x) {
      loggy.error("Upload failed, file path: ${_file!.path}", x);
      _uploadProgress = null;
      _uploadFailed = true;
    });
  }

}
