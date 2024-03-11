import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/source_photo.dart';

part 'maker_note_data.freezed.dart';
part 'maker_note_data.g.dart';

@freezed
abstract class MakerNoteData with _$MakerNoteData {

  const factory MakerNoteData({
    required List<SourcePhoto> sourcePhotos,
  }) = _MakerNoteData;

  factory MakerNoteData.fromJson(Map<String, Object?> json) => _$MakerNoteDataFromJson(json);

}
