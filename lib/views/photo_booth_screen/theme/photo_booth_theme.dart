// ignore_for_file: annotate_overrides

import 'package:fluent_ui/fluent_ui.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'photo_booth_theme.tailor.dart';

@TailorMixin()
class PhotoBoothTheme extends ThemeExtension<PhotoBoothTheme> with _$PhotoBoothThemeTailorMixin {

  final PhotoBoothButtonTheme buttonTheme;

  const PhotoBoothTheme({required this.buttonTheme});

}

@TailorMixinComponent()
class PhotoBoothButtonTheme extends ThemeExtension<PhotoBoothButtonTheme> with _$PhotoBoothButtonThemeTailorMixin {

  final ButtonStyle style;
  final Widget Function(BuildContext context, Widget child) frameBuilder;

  const PhotoBoothButtonTheme({required this.style, required this.frameBuilder});

}
