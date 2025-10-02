import 'dart:io';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/src/rust/utils/ffsend_client.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'share_screen_view_model.g.dart';

class ShareScreenViewModel = ShareScreenViewModelBase with _$ShareScreenViewModel;

abstract class ShareScreenViewModelBase extends ScreenViewModelBase with Store {

  ShareScreenViewModelBase({
    required super.contextAccessor,
  });

  bool get displayConfetti => getIt<ProjectManager>().settings.displayConfetti;
  late final ConfettiController confettiController = ConfettiController(duration: const Duration(milliseconds: 100))..play();

  Uint8List get outputImage => getIt<PhotosManager>().outputImage!;

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

  @readonly
  Size? _imageSize;

  List<Color>? getColors() {
    if (!getIt<ProjectManager>().settings.customColorConfetti) return null;
    final theme = FluentTheme.of(contextAccessor.buildContext);
    final accentColor = HSLColor.fromColor(theme.accentColor);
    final List<double> lValues = [0.2, 0.4, 0.5, 0.7, 0.9, 1];
    final accentColorsHSL = lValues.map((e) => HSLColor.fromAHSL(1, accentColor.hue, accentColor.saturation, e));
    final accentColors = accentColorsHSL.map((e) => e.toColor()).toList();

    return accentColors;
  }

  String get ffSendUrl => getIt<SettingsManager>().settings.output.firefoxSendServerUrl;
  CaptureMode get captureMode => getIt<PhotosManager>().captureMode;
  bool get canRetake {
    switch (captureMode) {
      case CaptureMode.single:
        return true;
      case CaptureMode.collage:
        return getIt<ProjectManager>().settings.collageMode != CollageMode.userSelection;
    }
  }
  String get backText => canRetake ? localizations.shareScreenRetakeButton : localizations.shareScreenChangeButton;

  Future<void> uploadPhotoToSend() async {
    _file ??= getIt<PhotosManager>().lastPhotoFile ?? await getIt<PhotosManager>().getOutputImageAsTempFile();
    final ext = getIt<SettingsManager>().settings.output.exportFormat.name.toLowerCase();

    logDebug("Uploading ${_file!.path}");

    // HHmmss string
    DateFormat formatter = DateFormat('HHmmss');
    String filename = "MomentoBooth ${formatter.format(DateTime.now())}.$ext";
    Stream<FfSendTransferProgress> stream = ffsendUploadFile(
      filePath: _file!.path,
      hostUrl: ffSendUrl,
      downloadFilename: filename,
      controlCommandTimeout: getIt<SettingsManager>().settings.output.firefoxSendControlCommandTimeout,
      transferTimeout: getIt<SettingsManager>().settings.output.firefoxSendTransferTimeout,
    );

    _uploadProgress = 0.0;
    _uploadFailed = false;

    stream.listen((event) async {
      if (event.isFinished) {
        logDebug("Upload complete: ${event.downloadUrl}");

        await Future.delayed(const Duration(milliseconds: 500));
        _qrUrl = event.downloadUrl;
        _uploadProgress = null;

        getIt<StatsManager>().addUploadedPhoto();
      } else {
        logDebug("Uploading: ${event.transferredBytes}/${event.totalBytes} bytes");
        _uploadProgress = event.transferredBytes / (event.totalBytes ?? 0);
      }
    }).onError((x) async {
      logError("Upload failed, file path: ${_file!.path}", x);
      await Future.delayed(const Duration(seconds: 1));
      _uploadProgress = null;
      _uploadFailed = true;
    });
  }

  void onImageDecoded(Size size) => _imageSize = size;

}
