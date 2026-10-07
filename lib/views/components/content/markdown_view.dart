import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders Markdown with the Fluent UI typography.
///
/// `flutter_markdown_plus` derives its default style sheet from the Material theme, so
/// this passes an explicit one built from [FluentTheme] to keep rendered Markdown in
/// line with the rest of the application. Links open in the system browser.
class MarkdownView extends StatelessWidget {

  final String data;

  /// The style used for paragraphs and list items. Defaults to the Fluent body style.
  final TextStyle? baseStyle;

  const MarkdownView({super.key, required this.data, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: _styleSheet(context),
      onTapLink: (text, href, title) => _openLink(href),
    );
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    Typography typography = FluentTheme.of(context).typography;
    TextStyle base = baseStyle ?? typography.body ?? const TextStyle();

    return MarkdownStyleSheet(
      p: base,
      listBullet: base,
      a: base.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
      strong: base.copyWith(fontWeight: FontWeight.bold),
      em: base.copyWith(fontStyle: FontStyle.italic),
      code: base.copyWith(fontFamily: "Consolas", backgroundColor: const Color(0x14000000)),
      h1: typography.title ?? base,
      h2: typography.subtitle ?? base,
      h3: typography.bodyStrong ?? base,
      h4: typography.bodyStrong ?? base,
      h5: typography.bodyStrong ?? base,
      h6: typography.bodyStrong ?? base,
      blockquoteDecoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: BorderRadius.circular(2.0),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: BorderRadius.circular(2.0),
      ),
      blockSpacing: 12.0,
      listIndent: 16.0,
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;

    Uri? uri = Uri.tryParse(href);
    if (uri != null) await launchUrl(uri);
  }

}
