// ignore_for_file: annotate_overrides

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/basic/basic_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/hollywood/hollywood_theme.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'photo_booth_theme.tailor.dart';

typedef WidgetBuilder = Widget Function(BuildContext context, Widget child);
typedef StatesWidgetBuilder = Widget Function(BuildContext context, Widget child, Set<WidgetState> states);

@TailorMixin()
class PhotoBoothTheme extends ThemeExtension<PhotoBoothTheme> with _$PhotoBoothThemeTailorMixin {

  final TextTheme titleTheme;
  final TextTheme subtitleTheme;
  final PhotoBoothButtonTheme actionButtonTheme;
  final PhotoBoothButtonTheme navigationButtonTheme;
  final CaptureCounterTheme captureCounterTheme;
  final DialogTheme dialogTheme;
  final CollagePreviewTheme collagePreviewTheme;
  final FullScreenPictureTheme fullScreenPictureTheme;
  final double Function(String route) screenLiveViewBlur;
  final Map<String, WidgetBuilder> screenWrappers;

  const PhotoBoothTheme({
    required this.titleTheme,
    required this.subtitleTheme,
    required this.actionButtonTheme,
    required this.navigationButtonTheme,
    required this.captureCounterTheme,
    required this.dialogTheme,
    required this.collagePreviewTheme,
    required this.fullScreenPictureTheme,
    required this.screenLiveViewBlur,
    this.screenWrappers = const {},
  });

  factory PhotoBoothTheme.defaultBasic({required Color primaryColor}) => basicTheme(primaryColor: primaryColor);
  factory PhotoBoothTheme.defaultHollywood({required Color primaryColor}) => hollywoodTheme(primaryColor: primaryColor);

}

@TailorMixinComponent()
class TextTheme extends ThemeExtension<TextTheme> with _$TextThemeTailorMixin {

  final TextStyle style;
  final WidgetBuilder? frameBuilder;

  const TextTheme({required this.style, this.frameBuilder});

}

@TailorMixinComponent()
class PhotoBoothButtonTheme extends ThemeExtension<PhotoBoothButtonTheme> with _$PhotoBoothButtonThemeTailorMixin {

  final ButtonStyle style;
  final StatesWidgetBuilder? frameBuilder;

  const PhotoBoothButtonTheme({required this.style, this.frameBuilder});

}

@TailorMixinComponent()
class CaptureCounterTheme extends ThemeExtension<CaptureCounterTheme> with _$CaptureCounterThemeTailorMixin {

  final TextStyle textStyle;
  final Color? ringColor;
  final double? ringStroke;
  final WidgetBuilder? frameBuilder;

  const CaptureCounterTheme({required this.textStyle, this.ringColor, this.ringStroke, this.frameBuilder});

}

@TailorMixinComponent()
class DialogTheme extends ThemeExtension<DialogTheme> with _$DialogThemeTailorMixin {

  final TextStyle titleStyle;
  final ButtonStyle buttonStyle;

  const DialogTheme({required this.titleStyle, required this.buttonStyle});

}

@TailorMixinComponent()
class CollagePreviewTheme extends ThemeExtension<CollagePreviewTheme> with _$CollagePreviewThemeTailorMixin {

  final WidgetBuilder? frameBuilder;

  const CollagePreviewTheme({required this.frameBuilder});

}

@TailorMixinComponent()
class FullScreenPictureTheme extends ThemeExtension<FullScreenPictureTheme> with _$FullScreenPictureThemeTailorMixin {

  final WidgetBuilder? frameBuilder;

  const FullScreenPictureTheme({required this.frameBuilder});

}
