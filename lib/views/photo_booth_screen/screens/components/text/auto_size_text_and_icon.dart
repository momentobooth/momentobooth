import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';

class AutoSizeTextAndIcon extends StatelessWidget {

  final String? text;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final TextStyle? textStyle;

  const AutoSizeTextAndIcon({
    super.key,
    this.text,
    this.leftIcon,
    this.rightIcon,
    this.textStyle,
  }) : assert(
         text != null || leftIcon != null || rightIcon != null,
         'At least one of text, leftIcon, or rightIcon must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    return AutoSizeText.rich(
      TextSpan(
        children: [
          if (leftIcon != null)
            TextSpan(
              text: String.fromCharCode(leftIcon!.codePoint),
              style: DefaultTextStyle.of(context).style.copyWith(fontFamily: leftIcon!.fontFamily),
            ),
          if (text != null)
            TextSpan(
              text: text,
              style: textStyle,
            ),
          if (rightIcon != null)
            TextSpan(
              text: String.fromCharCode(rightIcon!.codePoint),
              style: DefaultTextStyle.of(context).style.copyWith(fontFamily: rightIcon!.fontFamily),
            ),
        ],
      ),
      maxLines: 1,
    );
  }

}
