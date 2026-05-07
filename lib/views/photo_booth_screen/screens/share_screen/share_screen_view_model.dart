import 'dart:io';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/project_settings.dart';
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

  Future<void> ensureFile() async {
    _file ??= getIt<PhotosManager>().lastPhotoFile ?? await getIt<PhotosManager>().getOutputImageAsTempFile();
  }

  void onImageDecoded(Size size) => _imageSize = size;

}
