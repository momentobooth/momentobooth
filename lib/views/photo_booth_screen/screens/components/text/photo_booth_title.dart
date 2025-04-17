import 'package:flutter/material.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';

class PhotoBoothTitle extends StatelessWidget {

  final String text;

  const PhotoBoothTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget child = AutoSizeTextAndIcon(
      text: text,
      style: context.theme.titleTheme.style,
    );

    if (context.theme.titleTheme.frameBuilder != null) {
      return context.theme.titleTheme.frameBuilder!(context, child);
    } else {
      return child;
    }
  }

}
