// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'photo_booth_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$PhotoBoothThemeTailorMixin on ThemeExtension<PhotoBoothTheme> {
  TextTheme get titleTheme;
  TextTheme get subtitleTheme;
  PhotoBoothButtonTheme get primaryButtonTheme;
  PhotoBoothButtonTheme get navigationButtonTheme;
  CaptureCounterTheme get captureCounterTheme;
  DialogTheme get dialogTheme;

  @override
  PhotoBoothTheme copyWith({
    TextTheme? titleTheme,
    TextTheme? subtitleTheme,
    PhotoBoothButtonTheme? primaryButtonTheme,
    PhotoBoothButtonTheme? navigationButtonTheme,
    CaptureCounterTheme? captureCounterTheme,
    DialogTheme? dialogTheme,
  }) {
    return PhotoBoothTheme(
      titleTheme: titleTheme ?? this.titleTheme,
      subtitleTheme: subtitleTheme ?? this.subtitleTheme,
      primaryButtonTheme: primaryButtonTheme ?? this.primaryButtonTheme,
      navigationButtonTheme:
          navigationButtonTheme ?? this.navigationButtonTheme,
      captureCounterTheme: captureCounterTheme ?? this.captureCounterTheme,
      dialogTheme: dialogTheme ?? this.dialogTheme,
    );
  }

  @override
  PhotoBoothTheme lerp(
      covariant ThemeExtension<PhotoBoothTheme>? other, double t) {
    if (other is! PhotoBoothTheme) return this as PhotoBoothTheme;
    return PhotoBoothTheme(
      titleTheme: titleTheme.lerp(other.titleTheme, t) as TextTheme,
      subtitleTheme: subtitleTheme.lerp(other.subtitleTheme, t) as TextTheme,
      primaryButtonTheme: primaryButtonTheme.lerp(other.primaryButtonTheme, t)
          as PhotoBoothButtonTheme,
      navigationButtonTheme: navigationButtonTheme.lerp(
          other.navigationButtonTheme, t) as PhotoBoothButtonTheme,
      captureCounterTheme: captureCounterTheme.lerp(
          other.captureCounterTheme, t) as CaptureCounterTheme,
      dialogTheme: dialogTheme.lerp(other.dialogTheme, t) as DialogTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhotoBoothTheme &&
            const DeepCollectionEquality()
                .equals(titleTheme, other.titleTheme) &&
            const DeepCollectionEquality()
                .equals(subtitleTheme, other.subtitleTheme) &&
            const DeepCollectionEquality()
                .equals(primaryButtonTheme, other.primaryButtonTheme) &&
            const DeepCollectionEquality()
                .equals(navigationButtonTheme, other.navigationButtonTheme) &&
            const DeepCollectionEquality()
                .equals(captureCounterTheme, other.captureCounterTheme) &&
            const DeepCollectionEquality()
                .equals(dialogTheme, other.dialogTheme));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(titleTheme),
      const DeepCollectionEquality().hash(subtitleTheme),
      const DeepCollectionEquality().hash(primaryButtonTheme),
      const DeepCollectionEquality().hash(navigationButtonTheme),
      const DeepCollectionEquality().hash(captureCounterTheme),
      const DeepCollectionEquality().hash(dialogTheme),
    );
  }
}

extension PhotoBoothThemeThemeData on FluentThemeData {
  PhotoBoothTheme get photoBoothTheme => extension<PhotoBoothTheme>()!;
}

mixin _$TextThemeTailorMixin on ThemeExtension<TextTheme> {
  TextStyle get style;
  Widget Function(BuildContext, Widget)? get frameBuilder;

  @override
  TextTheme copyWith({
    TextStyle? style,
    Widget Function(BuildContext, Widget)? frameBuilder,
  }) {
    return TextTheme(
      style: style ?? this.style,
      frameBuilder: frameBuilder ?? this.frameBuilder,
    );
  }

  @override
  TextTheme lerp(covariant ThemeExtension<TextTheme>? other, double t) {
    if (other is! TextTheme) return this as TextTheme;
    return TextTheme(
      style: TextStyle.lerp(style, other.style, t)!,
      frameBuilder: t < 0.5 ? frameBuilder : other.frameBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TextTheme &&
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

mixin _$PhotoBoothButtonThemeTailorMixin
    on ThemeExtension<PhotoBoothButtonTheme> {
  ButtonStyle get style;
  Widget Function(BuildContext, Widget)? get frameBuilder;

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

mixin _$CaptureCounterThemeTailorMixin on ThemeExtension<CaptureCounterTheme> {
  TextStyle get textStyle;
  Widget Function(BuildContext, Widget)? get frameBuilder;

  @override
  CaptureCounterTheme copyWith({
    TextStyle? textStyle,
    Widget Function(BuildContext, Widget)? frameBuilder,
  }) {
    return CaptureCounterTheme(
      textStyle: textStyle ?? this.textStyle,
      frameBuilder: frameBuilder ?? this.frameBuilder,
    );
  }

  @override
  CaptureCounterTheme lerp(
      covariant ThemeExtension<CaptureCounterTheme>? other, double t) {
    if (other is! CaptureCounterTheme) return this as CaptureCounterTheme;
    return CaptureCounterTheme(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t)!,
      frameBuilder: t < 0.5 ? frameBuilder : other.frameBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CaptureCounterTheme &&
            const DeepCollectionEquality().equals(textStyle, other.textStyle) &&
            const DeepCollectionEquality()
                .equals(frameBuilder, other.frameBuilder));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(textStyle),
      const DeepCollectionEquality().hash(frameBuilder),
    );
  }
}

mixin _$DialogThemeTailorMixin on ThemeExtension<DialogTheme> {
  ButtonStyle get buttonStyle;

  @override
  DialogTheme copyWith({
    ButtonStyle? buttonStyle,
  }) {
    return DialogTheme(
      buttonStyle: buttonStyle ?? this.buttonStyle,
    );
  }

  @override
  DialogTheme lerp(covariant ThemeExtension<DialogTheme>? other, double t) {
    if (other is! DialogTheme) return this as DialogTheme;
    return DialogTheme(
      buttonStyle: t < 0.5 ? buttonStyle : other.buttonStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DialogTheme &&
            const DeepCollectionEquality()
                .equals(buttonStyle, other.buttonStyle));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(buttonStyle),
    );
  }
}
