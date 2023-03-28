import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'momento_booth_theme_data.freezed.dart';

@freezed
class MomentoBoothThemeData with _$MomentoBoothThemeData {

  const factory MomentoBoothThemeData({
    required Color defaultPageBackgroundColor,
    required Color primaryColor,
    required TextStyle titleStyle,
  }) = _MomentoBoothThemeData;

  factory MomentoBoothThemeData.defaults() => const MomentoBoothThemeData(
    // App wide
    defaultPageBackgroundColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF00FF00), // Green

    // Title
    titleStyle: TextStyle(
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
  );

}
