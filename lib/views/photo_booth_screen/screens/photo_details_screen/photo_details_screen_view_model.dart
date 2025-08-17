import 'dart:io';
import 'dart:ui';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/utils/ffsend_client.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:path/path.dart' as path;

part 'photo_details_screen_view_model.g.dart';

class PhotoDetailsScreenViewModel = PhotoDetailsScreenViewModelBase with _$PhotoDetailsScreenViewModel;

abstract class PhotoDetailsScreenViewModelBase extends ScreenViewModelBase with Store {

  final String photoId;

  PhotoDetailsScreenViewModelBase({
    required super.contextAccessor,
    required this.photoId,
  });

  Directory get outputDir => getIt<ProjectManager>().getOutputDir();
  File? get file => File(path.join(outputDir.path, photoId));
  Future<List<MomentoBoothExifTag>> get metadata async => await getMomentoBoothExifTagsFromFile(imageFilePath: file!.path);
  Future<GalleryImage> get galleryImage async => GalleryImage(file: file!, exifTags: await metadata);
  Future<MakerNoteData?> get makerNoteData async => (await galleryImage).makerNoteData;

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
  Size? _imageSize;

  String get ffSendUrl => getIt<SettingsManager>().settings.output.firefoxSendServerUrl;

  Future<void> uploadPhotoToSend() async {
    logDebug("Uploading ${file!.path}");

    String basename = path.basename(file!.path);
    Stream<FfSendTransferProgress> stream = ffsendUploadFile(filePath: file!.path, hostUrl: ffSendUrl, downloadFilename: basename);

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
    }).onError((e) async {
      logError("Upload failed, file path: ${file!.path}: $e");
      await Future.delayed(const Duration(seconds: 1));
      _uploadProgress = null;
      _uploadFailed = true;
    });
  }

  void onImageDecoded(Size size) => _imageSize = size;

}
