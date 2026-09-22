import 'dart:convert';

import 'package:momento_booth/models/markdown_node.dart';

/// Parses the small subset of Markdown that MomentoBooth's own documents use:
/// ATX headings, bullet lists (including nesting), paragraphs, and the inline
/// constructs `**bold**`, `*italic*`, `` `code` `` and `[text](url)`.
///
/// Anything it does not recognise is kept as literal text rather than dropped, so an
/// unexpected construct degrades to plain text instead of disappearing from the UI.
abstract final class MarkdownParser {

  static final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp _bulletPattern = RegExp(r'^([ \t]*)[-*+]\s+(.*)$');
  static final RegExp _leadingWhitespacePattern = RegExp(r'^[ \t]');

  static final RegExp _inlinePattern = RegExp(
    '`(?<code>[^`]+)`'
    r'|\*\*(?<bold>[^*]+)\*\*'
    r'|\*(?<italic>[^*]+)\*'
    '|_(?<italicAlt>[^_]+)_'
    r'|\[(?<linkText>[^\]]*)\]\((?<linkUrl>[^)\s]+)\)',
  );

  /// Parses [source] into a list of block level elements.
  static List<MarkdownBlock> parseBlocks(String source) {
    final blocks = <MarkdownBlock>[];

    // Bullets are collected as raw Markdown and only turned into spans when the list is
    // flushed, so that a wrapped bullet is parsed as one piece of Markdown.
    List<(int indent, String markdown)> bullets = [];
    List<String> paragraphLines = [];

    void flushBullets() {
      if (bullets.isEmpty) return;
      blocks.add(MarkdownBulletList(
        items: [for (final (indent, markdown) in bullets) MarkdownBulletItem(indent: indent, spans: parseSpans(markdown))],
      ));
      bullets = [];
    }

    void flushParagraph() {
      if (paragraphLines.isEmpty) return;
      blocks.add(MarkdownParagraph(spans: parseSpans(paragraphLines.join(' '))));
      paragraphLines = [];
    }

    void flushAll() {
      flushBullets();
      flushParagraph();
    }

    for (final line in const LineSplitter().convert(source)) {
      if (line.trim().isEmpty) {
        flushAll();
        continue;
      }

      final heading = _headingPattern.firstMatch(line);
      if (heading != null) {
        flushAll();
        blocks.add(MarkdownHeading(level: heading.group(1)!.length, spans: parseSpans(heading.group(2)!.trim())));
        continue;
      }

      final bullet = _bulletPattern.firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        bullets.add((_indentLevel(bullet.group(1)!), bullet.group(2)!.trim()));
        continue;
      }

      if (bullets.isNotEmpty && _leadingWhitespacePattern.hasMatch(line)) {
        // A wrapped continuation of the previous bullet.
        final (indent, markdown) = bullets.removeLast();
        bullets.add((indent, '$markdown ${line.trim()}'));
        continue;
      }

      flushBullets();
      paragraphLines.add(line.trim());
    }

    flushAll();
    return blocks;
  }

  /// Parses a single piece of inline Markdown into styled spans.
  static List<MarkdownSpan> parseSpans(String markdown) {
    final spans = <MarkdownSpan>[];
    int position = 0;

    void addLiteral(String value) {
      if (value.isNotEmpty) spans.add(MarkdownSpan(value));
    }

    for (final match in _inlinePattern.allMatches(markdown)) {
      addLiteral(markdown.substring(position, match.start));
      position = match.end;

      if (match.namedGroup('code') case final String code) {
        spans.add(MarkdownSpan(code, code: true));
      } else if (match.namedGroup('bold') case final String bold) {
        spans.add(MarkdownSpan(bold, bold: true));
      } else if (match.namedGroup('italic') case final String italic) {
        spans.add(MarkdownSpan(italic, italic: true));
      } else if (match.namedGroup('italicAlt') case final String italic) {
        spans.add(MarkdownSpan(italic, italic: true));
      } else if (match.namedGroup('linkUrl') case final String url) {
        final label = match.namedGroup('linkText')!;
        spans.add(MarkdownSpan(label.isEmpty ? url : label, url: url));
      }
    }

    addLiteral(markdown.substring(position));
    return spans;
  }

  static int _indentLevel(String whitespace) => whitespace.replaceAll('\t', '  ').length ~/ 2;

}
