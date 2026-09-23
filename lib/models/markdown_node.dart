// A minimal Markdown document model, covering the small subset of Markdown that
// MomentoBooth's own CHANGELOG.md uses. See lib/utils/markdown_parser.dart.

/// A block level element of a parsed Markdown document.
sealed class MarkdownBlock {

  const MarkdownBlock();

}

/// A heading, e.g. `## 0.16.1`. [level] is the number of leading `#` characters.
class MarkdownHeading extends MarkdownBlock {

  final int level;
  final List<MarkdownSpan> spans;

  const MarkdownHeading({required this.level, required this.spans});

}

/// A run of consecutive non-empty lines, joined into a single wrapped paragraph.
class MarkdownParagraph extends MarkdownBlock {

  final List<MarkdownSpan> spans;

  const MarkdownParagraph({required this.spans});

}

/// A run of consecutive `-`/`*` bullet lines.
class MarkdownBulletList extends MarkdownBlock {

  final List<MarkdownBulletItem> items;

  const MarkdownBulletList({required this.items});

}

/// A single bullet. [indent] is the nesting depth, starting at 0.
class MarkdownBulletItem {

  final int indent;
  final List<MarkdownSpan> spans;

  const MarkdownBulletItem({required this.indent, required this.spans});

}

/// An inline run of text with uniform styling.
class MarkdownSpan {

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  /// The link target when this span is part of a `[text](url)` link.
  final String? url;

  const MarkdownSpan(this.text, {this.bold = false, this.italic = false, this.code = false, this.url});

  bool get isLink => url != null;

}
