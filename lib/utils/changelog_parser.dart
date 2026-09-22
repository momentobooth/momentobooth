import 'package:momento_booth/models/changelog_section.dart';
import 'package:momento_booth/models/markdown_node.dart';
import 'package:momento_booth/utils/app_version.dart';
import 'package:momento_booth/utils/markdown_parser.dart';

/// Splits a `CHANGELOG.md` document into one [ChangelogSection] per released version.
///
/// Level 2 headings that are not a version (most notably `## Unreleased`) are skipped,
/// as are the document title and anything preceding the first version heading.
abstract final class ChangelogParser {

  static List<ChangelogSection> parse(String markdown) {
    final sections = <ChangelogSection>[];

    AppVersion? currentVersion;
    List<MarkdownBlock> currentBlocks = [];

    void flush() {
      AppVersion? version = currentVersion;
      if (version != null && currentBlocks.isNotEmpty) {
        sections.add(ChangelogSection(version: version.versionString, parsedVersion: version, blocks: currentBlocks));
      }
      currentBlocks = [];
    }

    for (final block in MarkdownParser.parseBlocks(markdown)) {
      if (block is MarkdownHeading && block.level <= 2) {
        flush();
        currentVersion = AppVersion.tryParse(block.spans.map((s) => s.text).join().trim());
        continue;
      }

      if (currentVersion != null) currentBlocks.add(block);
    }

    flush();
    return sections;
  }

}
