import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/settings.dart';

part 'collected_copy.freezed.dart';
part 'collected_copy.g.dart';

/// A copy that waits on a stack in collect mode until its sheet is printed.
@Freezed(fromJson: true, toJson: true)
sealed class CollectedCopy with _$CollectedCopy {

  const factory CollectedCopy({
    required String id,

    /// The print this copy belongs to. Its copies share [imageFile].
    required String printId,
    required String jobName,
    required String stackNodeId,
    required PrintSize size,

    /// The file name of the photo, in the folder of the waiting list.
    required String imageFile,

    /// The width of the photo divided by its height.
    required double aspectRatio,
    required DateTime addedAt,
  }) = _CollectedCopy;

  factory CollectedCopy.fromJson(Map<String, Object?> json) => _$CollectedCopyFromJson(json);

}
