import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toml/toml.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

// ///////////// //
// Root settings //
// ///////////// //

@freezed
abstract class Stats with _$Stats implements TomlEncodableValue {

  const Stats._();

  const factory Stats({
    @Default(0) int taps,
    @Default(0) int printedPhotos,
    @Default(0) int printedPhotosSmall,
    @Default(0) int printedPhotosTiny,
    @Default(0) int uploadedPhotos,
    @Default(0) int capturedPhotos,
    @Default(0) int createdSinglePhotos,
    @Default(0) int retakes,
    @Default(0) int collageChanges,
    @Default(0) int createdMultiCapturePhotos,
  }) = stats;

  factory Stats.fromJson(Map<String, Object?> json) => _$StatsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}
