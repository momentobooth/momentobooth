import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

PhotoBoothTheme basicTheme({required Color primaryColor}) => PhotoBoothTheme(
  titleTheme: TextTheme(style: _titleTextStyle),
  subtitleTheme: TextTheme(style: _subtitleTextStyle),
  screenLiveViewBlur: (route) => 0,

  actionButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _actionButtonTextStyle.color!.withAlpha(128),
        WidgetState.any: _actionButtonTextStyle.color,
      }),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(Border()),
      textStyle: WidgetStatePropertyAll(_actionButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_actionButtonTextStyle.fontSize! * 0.80),
    ),
  ),

  navigationButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _navigationButtonTextStyle.color!.withAlpha(128),
        WidgetState.any: _navigationButtonTextStyle.color,
      }),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(Border()),
      textStyle: WidgetStatePropertyAll(_navigationButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_navigationButtonTextStyle.fontSize! * 0.80),
    ),
  ),

  captureCounterTheme: CaptureCounterTheme(
    textStyle: _captureCounterTextStyle,
    ringColor: Color(0xFFFFFFFF),
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
    titleStyle: _dialogTitleStyle,
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

  collagePreviewTheme: CollagePreviewTheme(
    frameBuilder: (context, child) => DecoratedBox(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        boxShadow: [_heavyShadow],
      ),
      child: child,
    ),
  ),

  fullScreenPictureTheme: FullScreenPictureTheme(
    frameBuilder: (context, child) => DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [_heavyShadow],
      ),
      child: child,
    ),
  ),
);

const _rootTextStyle = TextStyle(
  fontFamily: "Brandon Grotesque",
  fontWeight: FontWeight.w300,
  shadows: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 4)],
  color: Color(0xFFFFFFFF),
);

final _titleTextStyle = _rootTextStyle.copyWith(fontSize: 120);
final _subtitleTextStyle = _rootTextStyle.copyWith(fontSize: 80);
final _dialogTitleStyle = TextStyle(fontFamily: "Brandon Grotesque", fontWeight: FontWeight.bold, fontSize: 32);
final _actionButtonTextStyle = _rootTextStyle.copyWith(fontSize: 100);
final _navigationButtonTextStyle = _rootTextStyle.copyWith(fontSize: 80);
final _captureCounterTextStyle = _rootTextStyle.copyWith(fontSize: 280);

const _heavyShadow = BoxShadow(color: Color.fromARGB(255, 0, 0, 0), offset: Offset(0, 3), blurRadius: 8);
