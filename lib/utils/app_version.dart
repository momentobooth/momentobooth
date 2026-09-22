/// A simple dotted numeric version, optionally followed by a build number, as used
/// by MomentoBooth for its releases (e.g. `0.16.1` or the release tag `0.16.1-122`).
///
/// This is deliberately not a full semantic version implementation: the project only
/// ever publishes `<major>.<minor>.<patch>` versions with a monotonically increasing
/// build number, so comparing the numeric parts is enough.
class AppVersion implements Comparable<AppVersion> {

  /// The numeric parts of the version, most significant first.
  final List<int> parts;

  /// The build number, when the parsed value carried one.
  final int? build;

  const AppVersion(this.parts, {this.build});

  static final RegExp _pattern = RegExp(r'^v?(\d+(?:\.\d+)*)(?:[-+](\d+))?$');

  /// Parses [value], returning `null` when it is not a version this class understands.
  ///
  /// Accepts an optional leading `v`, and both the `0.16.1-122` (release tag) and
  /// `0.16.1+122` (pubspec) build number separators.
  static AppVersion? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;

    return AppVersion(
      match.group(1)!.split('.').map(int.parse).toList(growable: false),
      build: match.group(2) == null ? null : int.parse(match.group(2)!),
    );
  }

  /// The version without its build number, e.g. `0.16.1`.
  String get versionString => parts.join('.');

  @override
  int compareTo(AppVersion other) {
    for (int i = 0; i < (parts.length > other.parts.length ? parts.length : other.parts.length); i++) {
      final comparison = _partAt(i).compareTo(other._partAt(i));
      if (comparison != 0) return comparison;
    }

    // Only compare build numbers when both versions carry one, so that a changelog
    // heading (`0.16.1`) is considered equal to its release tag (`0.16.1-122`).
    if (build == null || other.build == null) return 0;
    return build!.compareTo(other.build!);
  }

  int _partAt(int index) => index < parts.length ? parts[index] : 0;

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) => other is AppVersion && compareTo(other) == 0 && build == other.build;

  @override
  int get hashCode => Object.hash(versionString, build);

  @override
  String toString() => build == null ? versionString : '$versionString-$build';

}
