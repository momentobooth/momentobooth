// This file is "main.dart"
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {

  const factory Settings({
    required String firstName,
    required String lastName,
    required int age,
  }) = _Settings;

  factory Settings.withDefaults() => Settings(
        firstName: "X",
        lastName: "Y",
        age: 15,
      );

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);

}
