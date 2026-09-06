import 'dart:io';
import 'dart:ui';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/utils/ffsend_upload.dart';
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

  late final FfSendUpload upload = FfSendUpload(onUploaded: getIt<StatsManager>().addUploadedPhoto);

  @readonly
  Size? _imageSize;

  bool get qrSharingEnabled => getIt<SettingsManager>().settings.output.firefoxSendEnabled;

  Future<void> uploadPhotoToSend() {
    return upload.start(() async => (filePath: file!.path, downloadFilename: path.basename(file!.path)));
  }

  void onImageDecoded(Size size) => _imageSize = size;

  @override
  void dispose() {
    upload.dispose();
    super.dispose();
  }

}
