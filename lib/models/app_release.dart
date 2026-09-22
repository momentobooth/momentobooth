import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/utils/app_version.dart';

part 'app_release.freezed.dart';

/// A published MomentoBooth release, as returned by the GitHub releases API.
@freezed
abstract class AppRelease with _$AppRelease {

  const AppRelease._();

  const factory AppRelease({
    /// The Git tag of the release, e.g. `0.16.1-122`.
    required String tagName,

    /// The parsed [tagName].
    required AppVersion version,

    /// The URL of the release page on GitHub.
    required String htmlUrl,

    DateTime? publishedAt,
  }) = _AppRelease;

  /// Parses a single entry of the GitHub releases API response, returning `null` for
  /// drafts and for releases whose tag is not a version this application understands.
  static AppRelease? fromGitHubJson(Map<String, dynamic> json) {
    if (json['draft'] == true) return null;

    final tagName = json['tag_name'] as String?;
    if (tagName == null) return null;

    final version = AppVersion.tryParse(tagName);
    if (version == null) return null;

    final publishedAt = json['published_at'] as String?;

    return AppRelease(
      tagName: tagName,
      version: version,
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/momentobooth/momentobooth/releases/tag/$tagName',
      publishedAt: publishedAt == null ? null : DateTime.tryParse(publishedAt),
    );
  }

}
