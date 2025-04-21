import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Auto sizing text and icon widget, mostly written to facilitate titles and buttons with autosizing text and icons (both on the left and right size of the next).
///
/// This widget works in a bit of a hacky way. It first let's the auto_size_text library find the right size for the text to make the whole widget fit.
/// It then sizes down the icon to match the text size (calculating the size according to an icon to text size ratio).
///
/// It works, for the lack of me (SH) knowing a better way to archieve this.
class AutoSizeTextAndIcon extends StatefulWidget {

  final String? text;
  final IconData? leftIcon;
  final IconData? rightIcon;

  /// Used by [AutoSizeText] to group for sizing consistency purpose. Use when having multiple buttons of the same type on one screen.
  final AutoSizeGroup? autoSizeGroup;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  final double? iconSize;

  const AutoSizeTextAndIcon({super.key, this.text, this.leftIcon, this.rightIcon, this.autoSizeGroup, this.style, this.textAlign, this.maxLines = 1, this.iconSize})
    : assert(
        text != null || leftIcon != null || rightIcon != null,
        'At least one of text, leftIcon, or rightIcon must be provided.',
      );

  @override
  State<AutoSizeTextAndIcon> createState() => _AutoSizeTextAndIconState();

}

class _AutoSizeTextAndIconState extends State<AutoSizeTextAndIcon> {

  final AutoSizeGroup _group = AutoSizeGroup();
  final GlobalKey _textKey = GlobalKey();

  late double iconSize;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = widget.style ?? DefaultTextStyle.of(context).style;
    _updateIconSize();

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        // We seem to receive callbacks while the layout is going on.
        // Due to this, calls to setState without the post frame callback will cause an exception.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(_updateIconSize);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leftIcon != null)
              AutoSizeText(
                String.fromCharCode(widget.leftIcon!.codePoint),
                style: textStyle.copyWith(
                  fontFamily: widget.leftIcon!.fontFamily,
                  package: widget.leftIcon!.fontPackage,
                  fontSize: iconSize,
                ),
              ),
            if (widget.leftIcon != null && widget.text != null) // Left hand spacing
              AutoSizeText(
                ' ',
                style: textStyle,
                group: widget.autoSizeGroup ?? _group,
              ),
            if (widget.text != null)
              Flexible(
                child: AutoSizeText(
                  widget.text!,
                  textKey: _textKey,
                  style: textStyle,
                  maxLines: widget.maxLines,
                  group: widget.autoSizeGroup ?? _group,
                ),
              ),
            if (widget.rightIcon != null && widget.text != null) // Right hand spacing
              AutoSizeText(
                ' ',
                style: textStyle,
                group: widget.autoSizeGroup ?? _group,
              ),
            if (widget.rightIcon != null)
              AutoSizeText(
                String.fromCharCode(widget.rightIcon!.codePoint),
                style: textStyle.copyWith(
                  fontFamily: widget.rightIcon!.fontFamily,
                  package: widget.rightIcon!.fontPackage,
                  fontSize: iconSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateIconSize() {
    TextStyle textStyle = widget.style ?? DefaultTextStyle.of(context).style;
    double defaultIconSize = widget.iconSize ?? IconTheme.of(context).size ?? textStyle.fontSize ?? 24;

    double iconToTextSizeRatio = defaultIconSize / textStyle.fontSize!;
    iconSize = ((_textKey.currentWidget as Text?)?.style?.fontSize ?? defaultIconSize) * iconToTextSizeRatio;
  }

}

@UseCase(name: 'AutoSizeTextAndIcon action button', type: AutoSizeTextAndIcon)
Widget actionButton(BuildContext context) {
  return PhotoBoothButton.action(
    onPressed: context.knobs.boolean(label: "Disabled") ? null: () {},
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
    onPressed: context.knobs.boolean(label: "Disabled") ? null: () {},
    child: AutoSizeTextAndIcon(
      text: 'My Text',
      leftIcon: LucideIcons.airVent,
      rightIcon: LucideIcons.powerOff,
    ),
  );
}
