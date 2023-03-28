// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'momento_booth_theme_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$MomentoBoothThemeData {
  Color get defaultPageBackgroundColor => throw _privateConstructorUsedError;
  Color get primaryColor => throw _privateConstructorUsedError;
  TextStyle get titleStyle => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MomentoBoothThemeDataCopyWith<MomentoBoothThemeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MomentoBoothThemeDataCopyWith<$Res> {
  factory $MomentoBoothThemeDataCopyWith(MomentoBoothThemeData value,
          $Res Function(MomentoBoothThemeData) then) =
      _$MomentoBoothThemeDataCopyWithImpl<$Res, MomentoBoothThemeData>;
  @useResult
  $Res call(
      {Color defaultPageBackgroundColor,
      Color primaryColor,
      TextStyle titleStyle});
}

/// @nodoc
class _$MomentoBoothThemeDataCopyWithImpl<$Res,
        $Val extends MomentoBoothThemeData>
    implements $MomentoBoothThemeDataCopyWith<$Res> {
  _$MomentoBoothThemeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultPageBackgroundColor = null,
    Object? primaryColor = null,
    Object? titleStyle = null,
  }) {
    return _then(_value.copyWith(
      defaultPageBackgroundColor: null == defaultPageBackgroundColor
          ? _value.defaultPageBackgroundColor
          : defaultPageBackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as Color,
      titleStyle: null == titleStyle
          ? _value.titleStyle
          : titleStyle // ignore: cast_nullable_to_non_nullable
              as TextStyle,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_MomentoBoothThemeDataCopyWith<$Res>
    implements $MomentoBoothThemeDataCopyWith<$Res> {
  factory _$$_MomentoBoothThemeDataCopyWith(_$_MomentoBoothThemeData value,
          $Res Function(_$_MomentoBoothThemeData) then) =
      __$$_MomentoBoothThemeDataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Color defaultPageBackgroundColor,
      Color primaryColor,
      TextStyle titleStyle});
}

/// @nodoc
class __$$_MomentoBoothThemeDataCopyWithImpl<$Res>
    extends _$MomentoBoothThemeDataCopyWithImpl<$Res, _$_MomentoBoothThemeData>
    implements _$$_MomentoBoothThemeDataCopyWith<$Res> {
  __$$_MomentoBoothThemeDataCopyWithImpl(_$_MomentoBoothThemeData _value,
      $Res Function(_$_MomentoBoothThemeData) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultPageBackgroundColor = null,
    Object? primaryColor = null,
    Object? titleStyle = null,
  }) {
    return _then(_$_MomentoBoothThemeData(
      defaultPageBackgroundColor: null == defaultPageBackgroundColor
          ? _value.defaultPageBackgroundColor
          : defaultPageBackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as Color,
      titleStyle: null == titleStyle
          ? _value.titleStyle
          : titleStyle // ignore: cast_nullable_to_non_nullable
              as TextStyle,
    ));
  }
}

/// @nodoc

class _$_MomentoBoothThemeData implements _MomentoBoothThemeData {
  const _$_MomentoBoothThemeData(
      {required this.defaultPageBackgroundColor,
      required this.primaryColor,
      required this.titleStyle});

  @override
  final Color defaultPageBackgroundColor;
  @override
  final Color primaryColor;
  @override
  final TextStyle titleStyle;

  @override
  String toString() {
    return 'MomentoBoothThemeData(defaultPageBackgroundColor: $defaultPageBackgroundColor, primaryColor: $primaryColor, titleStyle: $titleStyle)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_MomentoBoothThemeData &&
            (identical(other.defaultPageBackgroundColor,
                    defaultPageBackgroundColor) ||
                other.defaultPageBackgroundColor ==
                    defaultPageBackgroundColor) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.titleStyle, titleStyle) ||
                other.titleStyle == titleStyle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, defaultPageBackgroundColor, primaryColor, titleStyle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_MomentoBoothThemeDataCopyWith<_$_MomentoBoothThemeData> get copyWith =>
      __$$_MomentoBoothThemeDataCopyWithImpl<_$_MomentoBoothThemeData>(
          this, _$identity);
}

abstract class _MomentoBoothThemeData implements MomentoBoothThemeData {
  const factory _MomentoBoothThemeData(
      {required final Color defaultPageBackgroundColor,
      required final Color primaryColor,
      required final TextStyle titleStyle}) = _$_MomentoBoothThemeData;

  @override
  Color get defaultPageBackgroundColor;
  @override
  Color get primaryColor;
  @override
  TextStyle get titleStyle;
  @override
  @JsonKey(ignore: true)
  _$$_MomentoBoothThemeDataCopyWith<_$_MomentoBoothThemeData> get copyWith =>
      throw _privateConstructorUsedError;
}
