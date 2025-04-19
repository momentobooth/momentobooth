import 'package:flutter/widgets.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';

class PhotoBoothTitle extends StatelessWidget {

  final String text;
  final TextAlign? textAlign;
  final int? maxLines;

  const PhotoBoothTitle(this.text, {super.key, this.textAlign, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    Widget child = AutoSizeTextAndIcon(
      text: text,
      style: context.theme.titleTheme.style,
      textAlign: textAlign,
      maxLines: maxLines,
    );

    return context.theme.titleTheme.frameBuilder?.call(context, child) ?? child;
  }

}
