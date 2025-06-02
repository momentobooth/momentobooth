import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/src/rust/models/images.dart';

part 'gallery_image.freezed.dart';

@freezed
abstract class GalleryImage with _$GalleryImage {

  const GalleryImage._();

  const factory GalleryImage({
    required File file,
    required List<MomentoBoothExifTag> exifTags,
  }) = _GalleryImage;

  /// Returns the created date of the image, based on the EXIF data, or file last modified timestamp.
  DateTime get createdDate => exifTags
    .whereType<MomentoBoothExifTag_CreateDate>()
    .firstOrNull?.field0 ?? file.lastModifiedSync();

  MakerNoteData? get makerNoteData {
    String? json = exifTags
      .whereType<MomentoBoothExifTag_MakerNote>()
      .firstOrNull?.field0;

    var trimmedJson = json?.replaceAll(String.fromCharCode(0), "");
    return trimmedJson == null ? null : MakerNoteData.fromJson(jsonDecode(trimmedJson));
  }

}
