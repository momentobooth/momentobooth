// ignore_for_file: annotate_overrides

import 'package:fluent_ui/fluent_ui.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'photo_booth_theme.tailor.dart';
part 'photo_booth_theme.basic_theme.dart';
part 'photo_booth_theme.wedding_theme.dart';

typedef WidgetBuilder = Widget Function(BuildContext context, Widget child);

@TailorMixin()
class PhotoBoothTheme extends ThemeExtension<PhotoBoothTheme> with _$PhotoBoothThemeTailorMixin {

  final TextTheme titleTheme;
  final TextTheme subtitleTheme;
  final PhotoBoothButtonTheme primaryButtonTheme;
  final PhotoBoothButtonTheme navigationButtonTheme;

  const PhotoBoothTheme({
    required this.titleTheme,
    required this.subtitleTheme,
    required this.primaryButtonTheme,
    required this.navigationButtonTheme,
  });

  factory PhotoBoothTheme.defaultBasic() => _basicTheme;
  //factory PhotoBoothTheme.defaultWedding() => _weddingTheme;

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
