// ignore_for_file: annotate_overrides

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.basic_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.wedding_theme.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'photo_booth_theme.tailor.dart';

typedef WidgetBuilder = Widget Function(BuildContext context, Widget child);

@TailorMixin()
class PhotoBoothTheme extends ThemeExtension<PhotoBoothTheme> with _$PhotoBoothThemeTailorMixin {

  final TextTheme titleTheme;
  final TextTheme subtitleTheme;
  final PhotoBoothButtonTheme actionButtonTheme;
  final PhotoBoothButtonTheme navigationButtonTheme;
  final CaptureCounterTheme captureCounterTheme;
  final DialogTheme dialogTheme;

  const PhotoBoothTheme({
    required this.titleTheme,
    required this.subtitleTheme,
    required this.actionButtonTheme,
    required this.navigationButtonTheme,
    required this.captureCounterTheme,
    required this.dialogTheme,
  });

  factory PhotoBoothTheme.defaultBasic() => basicTheme;
  factory PhotoBoothTheme.defaultWedding() => weddingTheme;

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
  final WidgetBuilder? frameBuilder;

  const PhotoBoothButtonTheme({required this.style, this.frameBuilder});

}

@TailorMixinComponent()
class CaptureCounterTheme extends ThemeExtension<CaptureCounterTheme> with _$CaptureCounterThemeTailorMixin {

  final TextStyle textStyle;
  final WidgetBuilder? frameBuilder;

  const CaptureCounterTheme({required this.textStyle, this.frameBuilder});

}

@TailorMixinComponent()
class DialogTheme extends ThemeExtension<DialogTheme> with _$DialogThemeTailorMixin {

  final ButtonStyle buttonStyle;

  const DialogTheme({required this.buttonStyle});

}
