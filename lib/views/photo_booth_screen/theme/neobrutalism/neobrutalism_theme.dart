import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/neobrutalism/components/neobrutalism_button_frame.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/neobrutalism/components/neobrutalism_title_frame.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

PhotoBoothTheme get neobrutalismTheme => PhotoBoothTheme(
  titleTheme: TextTheme(style: _titleTextStyle, frameBuilder: (_, child) => NeobrutalismTitleFrame(child: child)),
  subtitleTheme: TextTheme(style: _subtitleTextStyle),

  actionButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _actionButtonTextStyle.color!.withAlpha(128),
        WidgetState.any: _actionButtonTextStyle.color,
      }),
      backgroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: Colors.grey,
        WidgetState.any: Colors.yellow,
      }),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        side: BorderSide(width: 6),
        borderRadius: BorderRadius.circular(48),
      )),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 48, vertical: 32)),
      textStyle: WidgetStatePropertyAll(_actionButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_actionButtonTextStyle.fontSize! * 0.80),
    ),
    frameBuilder: (_, child, states) => NeobrutalismButtonFrame(states: states, radius: 48, child: child),
  ),

  navigationButtonTheme: PhotoBoothButtonTheme(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: _navigationButtonTextStyle.color!.withAlpha(128),
        WidgetState.any: _navigationButtonTextStyle.color,
      }),
      backgroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: Colors.grey,
        WidgetState.any: Colors.green.lighter,
      }),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        side: BorderSide(width: 6),
        borderRadius: BorderRadius.circular(32),
      )),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)),
      textStyle: WidgetStatePropertyAll(_navigationButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_navigationButtonTextStyle.fontSize! * 0.80),
    ),
    frameBuilder: (_, child, states) => NeobrutalismButtonFrame(states: states, radius: 32, child: child),
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

final _rootTextStyle = GoogleFonts.montserrat(
  color: Colors.black,
);

final _titleTextStyle = _rootTextStyle.copyWith(fontSize: 120);
final _subtitleTextStyle = _rootTextStyle.copyWith(fontSize: 80, color: Colors.white);
final _actionButtonTextStyle = _rootTextStyle.copyWith(fontSize: 100);
final _navigationButtonTextStyle = _rootTextStyle.copyWith(fontSize: 80);

const _heavyShadow = BoxShadow(color: Color.fromARGB(255, 0, 0, 0), offset: Offset(0, 3), blurRadius: 8);
