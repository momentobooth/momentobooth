// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'photo_booth_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$PhotoBoothThemeTailorMixin on ThemeExtension<PhotoBoothTheme> {
  PhotoBoothButtonTheme get buttonTheme;

  @override
  PhotoBoothTheme copyWith({
    PhotoBoothButtonTheme? buttonTheme,
  }) {
    return PhotoBoothTheme(
      buttonTheme: buttonTheme ?? this.buttonTheme,
    );
  }

  @override
  PhotoBoothTheme lerp(
      covariant ThemeExtension<PhotoBoothTheme>? other, double t) {
    if (other is! PhotoBoothTheme) return this as PhotoBoothTheme;
    return PhotoBoothTheme(
      buttonTheme:
          buttonTheme.lerp(other.buttonTheme, t) as PhotoBoothButtonTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoBoothTheme &&
            const DeepCollectionEquality()
                .equals(buttonTheme, other.buttonTheme));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(buttonTheme),
    );
  }
}

extension PhotoBoothThemeThemeData on FluentThemeData {
  PhotoBoothTheme get photoBoothTheme => extension<PhotoBoothTheme>()!;
}

mixin _$PhotoBoothButtonThemeTailorMixin
    on ThemeExtension<PhotoBoothButtonTheme> {
  ButtonStyle get style;
  Widget Function(BuildContext, Widget) get frameBuilder;

  @override
  PhotoBoothButtonTheme copyWith({
    ButtonStyle? style,
    Widget Function(BuildContext, Widget)? frameBuilder,
  }) {
    return PhotoBoothButtonTheme(
      style: style ?? this.style,
      frameBuilder: frameBuilder ?? this.frameBuilder,
    );
  }

  @override
  PhotoBoothButtonTheme lerp(
      covariant ThemeExtension<PhotoBoothButtonTheme>? other, double t) {
    if (other is! PhotoBoothButtonTheme) return this as PhotoBoothButtonTheme;
    return PhotoBoothButtonTheme(
      style: t < 0.5 ? style : other.style,
      frameBuilder: t < 0.5 ? frameBuilder : other.frameBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoBoothButtonTheme &&
            const DeepCollectionEquality().equals(style, other.style) &&
            const DeepCollectionEquality()
                .equals(frameBuilder, other.frameBuilder));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(style),
      const DeepCollectionEquality().hash(frameBuilder),
    );
  }
}
