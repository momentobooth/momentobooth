// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/source_photo.dart';
import 'package:momento_booth/src/rust/models/images.dart';

part 'maker_note_data.freezed.dart';
part 'maker_note_data.g.dart';

@freezed
abstract class MakerNoteData with _$MakerNoteData {

  const factory MakerNoteData({
    required List<SourcePhoto> sourcePhotos,
    @JsonKey(defaultValue: CreatedByMode.unknown) required CreatedByMode captureMode,
    int? peopleCount,
    List<List<int>>? faceLocations,
    String? faceEncodings,

    /// The collage padding on every side, as a fraction of the height of the image as it is stored. Printing uses it
    /// as the bleed. Null for photos made before it was stored.
    double? bleed,
  }) = _MakerNoteData;

  factory MakerNoteData.fromJson(Map<String, Object?> json) => _$MakerNoteDataFromJson(json);

  /// The maker note MomentoBooth wrote into the EXIF data of a collage, or null when [exifTags] have none.
  static MakerNoteData? fromExifTags(List<MomentoBoothExifTag> exifTags) {
    String? json = exifTags
      .whereType<MomentoBoothExifTag_MakerNote>()
      .firstOrNull?.field0;

    var trimmedJson = json?.replaceAll(String.fromCharCode(0), "");
    return trimmedJson == null ? null : MakerNoteData.fromJson(jsonDecode(trimmedJson));
  }

}

enum CreatedByMode {

  @JsonValue('single') single,
  @JsonValue('multi') multi,
  @JsonValue('manual') manual,
  unknown,

}
