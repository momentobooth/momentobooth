import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/maker_note_data.dart';
import 'package:momento_booth/src/rust/api/simple.dart';

part 'gallery_image.freezed.dart';

@freezed
abstract class GalleryImage with _$GalleryImage {

  const GalleryImage._();

  const factory GalleryImage({
    required File file,
    required List<MomentoBoothExifTag> exifTags,
  }) = _GalleryImage;

  DateTime? get createdDate => exifTags
    .whereType<MomentoBoothExifTag_CreateDate>()
    .firstOrNull?.field0;

  MakerNoteData? get makerNoteData {
    String? json = exifTags
      .whereType<MomentoBoothExifTag_MakerNote>()
      .firstOrNull?.field0;

    return json == null ? null : MakerNoteData.fromJson(jsonDecode(json));
  }

}
