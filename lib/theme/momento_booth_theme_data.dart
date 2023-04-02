import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'momento_booth_theme_data.freezed.dart';

@freezed
class MomentoBoothThemeData with _$MomentoBoothThemeData {

  const factory MomentoBoothThemeData({
    // App wide
    required Color defaultPageBackgroundColor,
    required Color primaryColor,

    // Title
    required TextStyle titleStyle,

    // Choose Capture Mode page
    required Color chooseCaptureModeButtonIconColor,
    required BoxShadow chooseCaptureModeButtonShadow,

    // Capture page
    required TextStyle captureCounterTextStyle,
    required BoxBorder captureCounterContainerBorder,
    required BorderRadius captureCounterContainerBorderRadius,
    required Color captureCounterContainerBackground,
    required BoxShadow captureCounterContainerShadow,
  }) = _MomentoBoothThemeData;

  factory MomentoBoothThemeData.defaults() => MomentoBoothThemeData(
    // App wide
    defaultPageBackgroundColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF00FF00), // Green

    // Title
    titleStyle: TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 120,
      fontWeight: FontWeight.w300,
      shadows: const [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 3),
          blurRadius: 4,
        ),
      ],
      color: Color(0xFFFFFFFF),
    ),

    // Choose Capture Mode page
    chooseCaptureModeButtonIconColor: Color(0xE6FFFFFF),
    chooseCaptureModeButtonShadow: BoxShadow(
      color: Color(0x42000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),

    // Capture page
    captureCounterTextStyle: TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 280,
      fontWeight: FontWeight.w300,
      shadows: const [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 3),
          blurRadius: 4,
        ),
      ],
      color: Color(0xFFFFFFFF),
    ),
    captureCounterContainerBorder: Border.all(width: 10, color: Color(0xFFFFFFFF)),
    captureCounterContainerBorderRadius: BorderRadius.circular(999),
    captureCounterContainerBackground: Color(0xAA000000),
    captureCounterContainerShadow: BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 3),
      blurRadius: 16,
    )
  );

}
