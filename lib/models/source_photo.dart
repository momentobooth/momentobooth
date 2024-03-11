import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_photo.freezed.dart';
part 'source_photo.g.dart';

@freezed
abstract class SourcePhoto with _$SourcePhoto {

  const factory SourcePhoto({
    required String filename,
    required String sha256,
  }) = _SourcePhoto;

  factory SourcePhoto.fromJson(Map<String, Object?> json) => _$SourcePhotoFromJson(json);

}
