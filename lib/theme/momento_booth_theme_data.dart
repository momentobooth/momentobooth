import 'package:figma_squircle/figma_squircle.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
    required TextStyle subTitleStyle,

    // Choose Capture Mode page
    required Color chooseCaptureModeButtonIconColor,
    required BoxShadow chooseCaptureModeButtonShadow,

    // Capture page
    required TextStyle captureCounterTextStyle,
    required BoxBorder captureCounterContainerBorder,
    required BorderRadius captureCounterContainerBorderRadius,
    required Color captureCounterContainerBackground,
    required BoxShadow captureCounterContainerShadow,

    // PhotoBoothDialog
    required ButtonStyle photoBoothDialogButtonStyle,
  }) = _MomentoBoothThemeData;

  factory MomentoBoothThemeData.defaults() => MomentoBoothThemeData(
    // App wide
    defaultPageBackgroundColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFF00FF00), // Green

    // Title
    titleStyle: const TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 120,
      fontWeight: FontWeight.w300,
      shadows: [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 3),
          blurRadius: 4,
        ),
      ],
      color: Color(0xFFFFFFFF),
    ),

    // Title
    subTitleStyle: const TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 80,
      fontWeight: FontWeight.w300,
      shadows: [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 3),
          blurRadius: 4,
        ),
      ],
      color: Color(0xFFFFFFFF),
    ),

    // Choose Capture Mode page
    chooseCaptureModeButtonIconColor: const Color(0xE6FFFFFF),
    chooseCaptureModeButtonShadow: const BoxShadow(
      color: Color(0x42000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),

    // Capture page
    captureCounterTextStyle: const TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 280,
      fontWeight: FontWeight.w300,
      shadows: [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 3),
          blurRadius: 4,
        ),
      ],
      color: Color(0xFFFFFFFF),
    ),
    captureCounterContainerBorder: Border.all(width: 10, color: const Color(0xFFFFFFFF)),
    captureCounterContainerBorderRadius: BorderRadius.circular(999),
    captureCounterContainerBackground: const Color(0xAA000000),
    captureCounterContainerShadow: const BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 3),
      blurRadius: 16,
    ),

    // PhotoBoothDialog
    photoBoothDialogButtonStyle: ButtonStyle(
      textStyle: ButtonState.all(const TextStyle(fontSize: 16.0)),
      padding: ButtonState.all(const EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0)),
      shape: ButtonState.all(
        SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 18,
            cornerSmoothing: 2,
          ),
        ),
      ),
    ),
  );

}
