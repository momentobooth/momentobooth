part of 'photo_booth_theme.dart';

PhotoBoothTheme get _basicTheme => PhotoBoothTheme(
  titleTheme: TextTheme(style: _basicTitleTextStyle),
  subtitleTheme: TextTheme(style: _basicSubtitleTextStyle),

  actionButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _basicSubtitleTextStyle.color!.withAlpha(128),
        WidgetState.any: _basicSubtitleTextStyle.color,
      }),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(Border()),
      textStyle: WidgetStatePropertyAll(_basicTitleTextStyle),
      iconSize: WidgetStatePropertyAll(_basicTitleTextStyle.fontSize),
    ),
  ),

  navigationButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _basicSubtitleTextStyle.color!.withAlpha(128),
        WidgetState.any: _basicSubtitleTextStyle.color,
      }),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(Border()),
      textStyle: WidgetStatePropertyAll(_basicSubtitleTextStyle),
      iconSize: WidgetStatePropertyAll(_basicSubtitleTextStyle.fontSize),
    ),
  ),

  captureCounterTheme: CaptureCounterTheme(
    textStyle: const TextStyle(
      fontFamily: "Brandon Grotesque",
      fontSize: 280,
      fontWeight: FontWeight.w300,
      shadows: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 4)],
      color: Color(0xFFFFFFFF),
    ),
    frameBuilder: (context, child) => DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x29000000), offset: Offset(0, 3), blurRadius: 16)],
      ),
      child: child,
    ),
  ),

  dialogTheme: DialogTheme(
    buttonStyle: ButtonStyle(
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16.0)),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0)),
      shape: WidgetStateProperty.all(
        ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(42),
        ),
      ),
    ),
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
