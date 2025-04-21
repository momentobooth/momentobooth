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
        side: BorderSide(width: 4),
        borderRadius: BorderRadius.circular(16),
      )),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 64, vertical: 16)),
      textStyle: WidgetStatePropertyAll(_actionButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_actionButtonTextStyle.fontSize),
    ),
    frameBuilder: (_, child, states) => NeobrutalismButtonFrame(states: states, radius: 16, shadowOffset: 8, child: child),
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
        side: BorderSide(width: 3),
        borderRadius: BorderRadius.circular(12),
      )),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
      textStyle: WidgetStatePropertyAll(_navigationButtonTextStyle),
      iconSize: WidgetStatePropertyAll(_navigationButtonTextStyle.fontSize),
    ),
    frameBuilder: (_, child, states) => NeobrutalismButtonFrame(states: states, radius: 12, shadowOffset: 6, child: child),
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

final _titleTextStyle = GoogleFonts.rubikMonoOne(color: Colors.black, fontSize: 80);
final _subtitleTextStyle = GoogleFonts.archivoBlack(color: Colors.white, fontSize: 60);
final _actionButtonTextStyle = GoogleFonts.spaceMono(color: Colors.black, fontSize: 64, fontWeight: FontWeight.w600);
final _navigationButtonTextStyle = GoogleFonts.spaceMono(color: Colors.black, fontSize: 48, fontWeight: FontWeight.w600);

const _heavyShadow = BoxShadow(color: Color.fromARGB(255, 0, 0, 0), offset: Offset(0, 3), blurRadius: 8);
