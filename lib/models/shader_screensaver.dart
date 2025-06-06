import 'package:freezed_annotation/freezed_annotation.dart';

part 'shader_screensaver.freezed.dart';
part 'shader_screensaver.g.dart';

@freezed
abstract class ShaderScreensaver with _$ShaderScreensaver {

  const factory ShaderScreensaver({
    required String title,
    required String author,
    required String sourceUrl,
    required String screensaverTimeDilation,
  }) = _ShaderScreensaver;

  factory ShaderScreensaver.fromJson(Map<String, Object?> json) => _$ShaderScreensaverFromJson(json);

}
