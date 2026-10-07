import 'dart:convert';

import 'package:momento_booth/models/changelog_section.dart';
import 'package:momento_booth/utils/app_version.dart';

/// Splits a `CHANGELOG.md` document into one [ChangelogSection] per released version.
///
/// Level 2 headings that are not a version (most notably `## Unreleased`) are skipped,
/// as is anything preceding the first version heading. The section bodies are left as
/// Markdown for the renderer to deal with.
abstract final class ChangelogParser {

  static final RegExp _headingPattern = RegExp(r'^#{1,2}\s+(.*)$');

  static List<ChangelogSection> parse(String markdown) {
    final sections = <ChangelogSection>[];

    AppVersion? currentVersion;
    List<String> currentLines = [];

    void flush() {
      AppVersion? version = currentVersion;
      String body = currentLines.join('\n').trim();
      if (version != null && body.isNotEmpty) {
        sections.add(ChangelogSection(version: version.versionString, parsedVersion: version, body: body));
      }
      currentLines = [];
    }

    for (final line in const LineSplitter().convert(markdown)) {
      final heading = _headingPattern.firstMatch(line);
      if (heading != null) {
        flush();
        currentVersion = AppVersion.tryParse(heading.group(1)!.trim());
        continue;
      }

      if (currentVersion != null) currentLines.add(line);
    }

    flush();
    return sections;
  }

}
