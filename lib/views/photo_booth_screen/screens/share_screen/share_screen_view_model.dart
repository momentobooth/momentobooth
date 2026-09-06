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
import 'package:momento_booth/utils/ffsend_upload.dart';
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

  late final FfSendUpload upload = FfSendUpload(onUploaded: getIt<StatsManager>().addUploadedPhoto);

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

  bool get qrSharingEnabled => getIt<SettingsManager>().settings.output.firefoxSendEnabled;
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

  Future<void> uploadPhotoToSend() {
    return upload.start(() async {
      _file ??= getIt<PhotosManager>().lastPhotoFile ?? await getIt<PhotosManager>().getOutputImageAsTempFile();
      final ext = getIt<SettingsManager>().settings.output.exportFormat.name.toLowerCase();

      // HHmmss string
      DateFormat formatter = DateFormat('HHmmss');
      return (
        filePath: _file!.path,
        downloadFilename: "MomentoBooth ${formatter.format(DateTime.now())}.$ext",
      );
    });
  }

  void onImageDecoded(Size size) => _imageSize = size;

  @override
  void dispose() {
    upload.dispose();
    super.dispose();
  }

}
