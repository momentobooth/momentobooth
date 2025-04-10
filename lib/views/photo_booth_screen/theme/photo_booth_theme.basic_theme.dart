part of 'photo_booth_theme.dart';

PhotoBoothTheme get _basicTheme => PhotoBoothTheme(
  titleTheme: TextTheme(style: _basicTitleTextStyle),
  subtitleTheme: TextTheme(style: _basicSubtitleTextStyle),

  primaryButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(textStyle: WidgetStateProperty.all(_basicTitleTextStyle))
  ),

  navigationButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(textStyle: WidgetStateProperty.all(_basicTitleTextStyle)),
  ),
);

const _basicTitleTextStyle = TextStyle(
  fontFamily: "Brandon Grotesque",
  fontSize: 120,
  fontWeight: FontWeight.w300,
  shadows: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 4)],
  color: Color(0xFFFFFFFF),
);

const _basicSubtitleTextStyle = TextStyle(
  fontFamily: "Brandon Grotesque",
  fontSize: 80,
  fontWeight: FontWeight.w300,
  shadows: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 4)],
  color: Color(0xFFFFFFFF),
);
