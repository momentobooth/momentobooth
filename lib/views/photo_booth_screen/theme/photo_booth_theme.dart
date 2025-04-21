// ignore_for_file: annotate_overrides

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/basic/basic_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/neobrutalism/neobrutalism_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/wedding/wedding_theme.dart';
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
    this.screenWrappers = const {},
  });

  factory PhotoBoothTheme.defaultBasic() => basicTheme;
  factory PhotoBoothTheme.defaultWedding() => weddingTheme;
  factory PhotoBoothTheme.defaultNeobrutalism() => neobrutalismTheme;

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
  final WidgetBuilder? frameBuilder;

  const CaptureCounterTheme({required this.textStyle, this.frameBuilder});

}

@TailorMixinComponent()
class DialogTheme extends ThemeExtension<DialogTheme> with _$DialogThemeTailorMixin {

  final ButtonStyle buttonStyle;

  const DialogTheme({required this.buttonStyle});

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
