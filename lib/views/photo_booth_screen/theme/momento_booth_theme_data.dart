import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'momento_booth_theme_data.freezed.dart';

@freezed
class MomentoBoothThemeData with _$MomentoBoothThemeData {

  const factory MomentoBoothThemeData({
    // Choose Capture Mode page
    required Color chooseCaptureModeButtonIconColor,
    required BoxShadow chooseCaptureModeButtonShadow,
  }) = _MomentoBoothThemeData;

  factory MomentoBoothThemeData.defaults() => MomentoBoothThemeData(
    // Choose Capture Mode page
    chooseCaptureModeButtonIconColor: const Color(0xE6FFFFFF),
    chooseCaptureModeButtonShadow: const BoxShadow(
      color: Color(0x42000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
  );

}
