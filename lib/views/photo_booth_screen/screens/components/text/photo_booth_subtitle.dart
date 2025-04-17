import 'package:flutter/widgets.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';

class PhotoBoothSubtitle extends StatelessWidget {

  final String text;
  final TextAlign? textAlign;

  const PhotoBoothSubtitle(this.text, {super.key, this.textAlign});

  @override
  Widget build(BuildContext context) {
    Widget child = AutoSizeTextAndIcon(
      text: text,
      style: context.theme.subtitleTheme.style,
      textAlign: textAlign,
    );

    if (context.theme.subtitleTheme.frameBuilder != null) {
      return context.theme.subtitleTheme.frameBuilder!(context, child);
    } else {
      return child;
    }
  }

}
