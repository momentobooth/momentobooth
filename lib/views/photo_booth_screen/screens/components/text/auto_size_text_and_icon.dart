import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class AutoSizeTextAndIcon extends StatefulWidget {

  final String? text;
  final IconData? leftIcon;
  final IconData? rightIcon;

  /// Used by [AutoSizeText] to group for sizing consistency purpose. Use when having multiple buttons of the same type on one screen.
  final AutoSizeGroup? autoSizeGroup;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const AutoSizeTextAndIcon({super.key, this.text, this.leftIcon, this.rightIcon, this.autoSizeGroup, this.style, this.textAlign, this.maxLines = 1})
    : assert(
        text != null || leftIcon != null || rightIcon != null,
        'At least one of text, leftIcon, or rightIcon must be provided.',
      );

  @override
  State<AutoSizeTextAndIcon> createState() => _AutoSizeTextAndIconState();

}

class _AutoSizeTextAndIconState extends State<AutoSizeTextAndIcon> {

  final AutoSizeGroup _group = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leftIcon != null)
          AutoSizeText(
            String.fromCharCode(widget.leftIcon!.codePoint),
            style: style.copyWith(
              fontFamily: widget.leftIcon!.fontFamily,
              package: widget.leftIcon!.fontPackage,
              fontSize: style.fontSize,
            ),
            group: widget.autoSizeGroup ?? _group,
          ),
        if (widget.leftIcon != null && widget.text != null) // Left hand spacing
          AutoSizeText(
            ' ',
            style: style,
            group: widget.autoSizeGroup ?? _group,
          ),
        if (widget.text != null)
          Flexible(
            child: AutoSizeText(
              widget.text!,
              style: style,
              maxLines: widget.maxLines,
              group: widget.autoSizeGroup ?? _group,
            ),
          ),
        if (widget.rightIcon != null && widget.text != null) // Right hand spacing
          AutoSizeText(
            ' ',
            style: style,
            group: widget.autoSizeGroup ?? _group,
          ),
        if (widget.rightIcon != null)
          AutoSizeText(
            String.fromCharCode(widget.rightIcon!.codePoint),
            style: style.copyWith(
              fontFamily: widget.rightIcon!.fontFamily,
              package: widget.rightIcon!.fontPackage,
              fontSize: style.fontSize,
            ),
            group: widget.autoSizeGroup ?? _group,
          ),
      ],
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
