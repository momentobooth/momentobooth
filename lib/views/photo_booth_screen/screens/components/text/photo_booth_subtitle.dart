import 'package:flutter/material.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';

class PhotoBoothSubtitle extends StatelessWidget {

  final String text;

  const PhotoBoothSubtitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget child = AutoSizeTextAndIcon(
      text: text,
      style: context.theme.subtitleTheme.style,
    );

    if (context.theme.subtitleTheme.frameBuilder != null) {
      return context.theme.subtitleTheme.frameBuilder!(context, child);
    } else {
      return child;
    }
  }

}
