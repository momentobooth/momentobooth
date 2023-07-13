import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/slider_widget.dart';
import 'package:path/path.dart' hide context;

part 'photo_details_screen_view_model.g.dart';

enum UploadState {
  notStarted,
  uploading,
  errored,
  done
}

class PhotoDetailsScreenViewModel = PhotoDetailsScreenViewModelBase with _$PhotoDetailsScreenViewModel;

abstract class PhotoDetailsScreenViewModelBase extends ScreenViewModelBase with Store {

  final String photoId;

  PhotoDetailsScreenViewModelBase({
    required super.contextAccessor,
    required this.photoId,
  });
  
  Directory get outputDir => Directory(SettingsManager.instance.settings.output.localFolder);
  File get file => File(join(outputDir.path, photoId));

  @observable
  late String qrText = localizations.photoDetailsScreenGetQrButton;

  @observable
  late String printText = localizations.genericPrintButton;

  @observable
  bool printEnabled = true;

  @observable
  UploadState uploadState = UploadState.notStarted;

  @observable
  bool qrShown = false;

  @observable
  String qrUrl = "";

  /// Global key for controlling the slider widget.
  GlobalKey<SliderWidgetState> sliderKey = GlobalKey<SliderWidgetState>();

}
