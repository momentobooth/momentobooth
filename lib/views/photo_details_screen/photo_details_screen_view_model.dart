import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/src/rust/utils/ffsend_client.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:path/path.dart' as path;

part 'photo_details_screen_view_model.g.dart';

class PhotoDetailsScreenViewModel = PhotoDetailsScreenViewModelBase with _$PhotoDetailsScreenViewModel;

abstract class PhotoDetailsScreenViewModelBase extends ScreenViewModelBase with Store, UiLoggy {

  final String photoId;

  PhotoDetailsScreenViewModelBase({
    required super.contextAccessor,
    required this.photoId,
  });
  
  Directory get outputDir => Directory(SettingsManager.instance.settings.output.localFolder);
  File? get file => File(path.join(outputDir.path, photoId));

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

  String get ffSendUrl => SettingsManager.instance.settings.output.firefoxSendServerUrl;

  Future<void> uploadPhotoToSend() async {
    loggy.debug("Uploading ${file!.path}");

    String basename = path.basename(file!.path);
    Stream<FfSendTransferProgress> stream = ffsendUploadFile(filePath: file!.path, hostUrl: ffSendUrl, downloadFilename: basename);

    _uploadProgress = 0.0;
    _uploadFailed = false;

    stream.listen((event) async {
      if (event.isFinished) {
        loggy.debug("Upload complete: ${event.downloadUrl}");

        await Future.delayed(const Duration(milliseconds: 500));
        _qrUrl = event.downloadUrl;
        _uploadProgress = null;

        StatsManager.instance.addUploadedPhoto();
      } else {
        loggy.debug("Uploading: ${event.transferredBytes}/${event.totalBytes} bytes");
        _uploadProgress = event.transferredBytes / (event.totalBytes ?? 0);
      }
    }).onError((x) async {
      loggy.error("Upload failed, file path: ${file!.path}", x);
      await Future.delayed(const Duration(seconds: 1));
      _uploadProgress = null;
      _uploadFailed = true;
    });
  }

}
