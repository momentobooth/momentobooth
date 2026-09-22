import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:momento_booth/models/markdown_node.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders the blocks produced by `MarkdownParser` using the Fluent UI typography.
///
/// Only the constructs MomentoBooth's own documents use are styled; see
/// [MarkdownBlock] for the supported subset.
class MarkdownView extends StatefulWidget {

  final List<MarkdownBlock> blocks;

  /// The style used for paragraphs and bullets. Defaults to the Fluent body style.
  final TextStyle? baseStyle;

  const MarkdownView({super.key, required this.blocks, this.baseStyle});

  @override
  State<MarkdownView> createState() => _MarkdownViewState();

}

class _MarkdownViewState extends State<MarkdownView> {

  final List<TapGestureRecognizer> _recognizers = [];

  static const double _blockSpacing = 12.0;
  static const double _bulletSpacing = 4.0;
  static const double _bulletIndent = 16.0;

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    Typography typography = FluentTheme.of(context).typography;
    TextStyle baseStyle = widget.baseStyle ?? typography.body ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _blockSpacing,
      children: [for (final block in widget.blocks) _buildBlock(context, block, typography, baseStyle)],
    );
  }

  Widget _buildBlock(BuildContext context, MarkdownBlock block, Typography typography, TextStyle baseStyle) {
    return switch (block) {
      MarkdownHeading(:final level, :final spans) => Text.rich(
          _buildSpan(spans, _headingStyle(level, typography, baseStyle)),
        ),
      MarkdownParagraph(:final spans) => Text.rich(_buildSpan(spans, baseStyle)),
      MarkdownBulletList(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _bulletSpacing,
          children: [for (final item in items) _buildBulletItem(item, baseStyle)],
        ),
    };
  }

  Widget _buildBulletItem(MarkdownBulletItem item, TextStyle baseStyle) {
    return Padding(
      padding: EdgeInsets.only(left: item.indent * _bulletIndent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: _bulletIndent, child: Text("•", style: baseStyle)),
          Expanded(child: Text.rich(_buildSpan(item.spans, baseStyle))),
        ],
      ),
    );
  }

  TextStyle _headingStyle(int level, Typography typography, TextStyle baseStyle) {
    return switch (level) {
      1 => typography.title ?? baseStyle,
      2 => typography.subtitle ?? baseStyle,
      _ => typography.bodyStrong ?? baseStyle,
    };
  }

  InlineSpan _buildSpan(List<MarkdownSpan> spans, TextStyle baseStyle) {
    return TextSpan(children: [for (final span in spans) _buildInlineSpan(span, baseStyle)]);
  }

  InlineSpan _buildInlineSpan(MarkdownSpan span, TextStyle baseStyle) {
    TextStyle style = baseStyle.copyWith(
      fontWeight: span.bold ? FontWeight.bold : null,
      fontStyle: span.italic ? FontStyle.italic : null,
      fontFamily: span.code ? "Consolas" : null,
      backgroundColor: span.code ? const Color(0x14000000) : null,
      color: span.isLink ? Colors.blue : null,
      decoration: span.isLink ? TextDecoration.underline : null,
    );

    if (!span.isLink) return TextSpan(text: span.text, style: style);

    TapGestureRecognizer recognizer = TapGestureRecognizer()..onTap = () => _openLink(span.url!);
    _recognizers.add(recognizer);
    return TextSpan(text: span.text, style: style, recognizer: recognizer);
  }

  Future<void> _openLink(String url) async {
    Uri? uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri);
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

}
