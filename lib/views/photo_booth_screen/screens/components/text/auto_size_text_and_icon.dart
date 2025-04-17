import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class AutoSizeTextAndIcon extends StatelessWidget {

  final String? text;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final AutoSizeGroup? autoSizeGroup;
  final TextStyle? style;

  const AutoSizeTextAndIcon({super.key, this.text, this.leftIcon, this.rightIcon, this.autoSizeGroup, this.style})
    : assert(
        text != null || leftIcon != null || rightIcon != null,
        'At least one of text, leftIcon, or rightIcon must be provided.',
      );

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final iconSize = defaultStyle.fontSize! * 0.70;
    const spacing = TextSpan(text: ' ');

    return AutoSizeText.rich(
      TextSpan(
        children: [
          if (leftIcon != null) ...[
            spacing,
            TextSpan(
              text: String.fromCharCode(leftIcon!.codePoint),
              style: defaultStyle.copyWith(
                fontFamily: leftIcon!.fontFamily,
                package: leftIcon!.fontPackage,
                fontSize: iconSize,
              ),
            ),
            spacing,
          ],
          if (text != null) TextSpan(text: text, style: defaultStyle),
          if (rightIcon != null) ...[
            spacing,
            TextSpan(
              text: String.fromCharCode(rightIcon!.codePoint),
              style: defaultStyle.copyWith(
                fontFamily: rightIcon!.fontFamily,
                package: rightIcon!.fontPackage,
                fontSize: iconSize,
              ),
            ),
            spacing,
          ],
        ],
      ),
      maxLines: 1,
      group: autoSizeGroup,
    );
  }

}

@UseCase(name: 'AutoSizeTextAndIcon action button', type: AutoSizeTextAndIcon)
Widget actionButton(BuildContext context) {
  return PhotoBoothButton.action(
    child: AutoSizeTextAndIcon(
      text: 'My Text',
      leftIcon: LucideIcons.airVent,
      rightIcon: LucideIcons.powerOff,
    ),
  );
}

@UseCase(name: 'AutoSizeTextAndIcon navigation button', type: AutoSizeTextAndIcon)
Widget navigationButton(BuildContext context) {
  return PhotoBoothButton.navigation(
    child: AutoSizeTextAndIcon(
      text: 'My Text',
      leftIcon: LucideIcons.airVent,
      rightIcon: LucideIcons.powerOff,
    ),
  );
}
