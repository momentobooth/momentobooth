
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/gallery_image.dart';

part 'gallery_group.freezed.dart';

@freezed
abstract class GalleryGroup with _$GalleryGroup {

  const GalleryGroup._();

  const factory GalleryGroup({
    DateTime? createdDayAndHour,
    required String title,
    required List<GalleryImage> images,
  }) = _GalleryGroup;

}
