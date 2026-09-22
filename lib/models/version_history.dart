import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toml/toml.dart';

part 'version_history.freezed.dart';
part 'version_history.g.dart';

/// Keeps track of which application version was taken into use on which date.
@freezed
abstract class VersionHistory with _$VersionHistory implements TomlEncodableValue {

  const VersionHistory._();

  const factory VersionHistory({
    @Default([]) List<VersionHistoryEntry> entries,
  }) = _VersionHistory;

  factory VersionHistory.fromJson(Map<String, Object?> json) => _$VersionHistoryFromJson(json);

  /// The entries ordered by the moment they were first used, oldest first.
  List<VersionHistoryEntry> get entriesByFirstUse => entries.sorted((a, b) => a.firstUsed.compareTo(b.firstUsed));

  /// The entry for the version that is currently in use, i.e. the most recently started one.
  VersionHistoryEntry? get current => entries.sorted((a, b) => a.lastUsed.compareTo(b.lastUsed)).lastOrNull;

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

/// A single version that has been used, and when.
@freezed
abstract class VersionHistoryEntry with _$VersionHistoryEntry implements TomlEncodableValue {

  const VersionHistoryEntry._();

  const factory VersionHistoryEntry({
    /// The application version, e.g. `0.16.1`.
    required String version,

    /// The build number belonging to [version].
    required int build,

    /// The first time this version was started.
    required DateTime firstUsed,

    /// The most recent time this version was started.
    required DateTime lastUsed,

    /// How often this version has been started.
    @Default(1) int startCount,
  }) = _VersionHistoryEntry;

  factory VersionHistoryEntry.fromJson(Map<String, Object?> json) => _$VersionHistoryEntryFromJson(json);

  /// The version including its build number, e.g. `0.16.1-122`.
  String get fullVersion => '$version-$build';

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}
