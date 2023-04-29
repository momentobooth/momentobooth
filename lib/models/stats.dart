import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toml/toml.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

// ///////////// //
// Root settings //
// ///////////// //

@freezed
class Stats with _$Stats implements TomlEncodableValue {
  
  const Stats._();

  const factory Stats({
    required int taps,
    required int liveViewFrames,
    required int printedPhotos,
    required int uploadedPhotos,
    required int capturedPhotos,
    required int createdSinglePhotos,
    required int retakes,
    required int createdMultiCapturePhotos,
  }) = _Stats;

  factory Stats.fromJson(Map<String, Object?> json) => _$StatsFromJson(json);
  
  @override
  Map<String, dynamic> toTomlValue() => toJson();

}
