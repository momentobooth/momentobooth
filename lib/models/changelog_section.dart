import 'package:momento_booth/models/markdown_node.dart';
import 'package:momento_booth/utils/app_version.dart';

/// The changelog entries belonging to a single released version.
class ChangelogSection {

  /// The version as written in the changelog heading, e.g. `0.16.1`.
  final String version;

  final AppVersion parsedVersion;

  /// The body of the section, as parsed Markdown blocks.
  final List<MarkdownBlock> blocks;

  const ChangelogSection({required this.version, required this.parsedVersion, required this.blocks});

}
