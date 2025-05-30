import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PhotoBoothButton extends StatefulWidget {

  final ButtonType type;
  final VoidCallback? onPressed;
  final Widget child;

  const PhotoBoothButton._({super.key, this.type = ButtonType.action, this.onPressed, required this.child});

  const PhotoBoothButton.action({Key? key, VoidCallback? onPressed, required Widget child})
    : this._(key: key, type: ButtonType.action, onPressed: onPressed, child: child);

  const PhotoBoothButton.navigation({Key? key, VoidCallback? onPressed, required Widget child})
    : this._(key: key, type: ButtonType.navigation, onPressed: onPressed, child: child);

  @override
  State<PhotoBoothButton> createState() => _PhotoBoothButtonState();

}

class _PhotoBoothButtonState extends State<PhotoBoothButton> {

  Set<WidgetState> _buttonStates = const {};

  @override
  Widget build(BuildContext context) {
    PhotoBoothTheme theme = FluentTheme.of(context).photoBoothTheme;
    PhotoBoothButtonTheme buttonTheme = switch (widget.type) {
      ButtonType.action => theme.actionButtonTheme,
      ButtonType.navigation => theme.navigationButtonTheme,
    };

    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Button(
        style: buttonTheme.style,
        onPressed: widget.onPressed,
        child: Builder(
          builder: (context) {
            // Copy over Fluent UI's button state to our state.
            Set<WidgetState> currentStates = HoverButton.of(context).states;
            if (!setEquals(_buttonStates, currentStates)) {
              _buttonStates = currentStates;
              WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
            }
            return widget.child;
          },
        ),
      ),
    );

    return buttonTheme.frameBuilder?.call(context, button, _buttonStates) ?? button;
  }

}

enum ButtonType { action, navigation }

@UseCase(name: 'Action button', type: PhotoBoothButton)
Widget actionButton(BuildContext context) {
  return PhotoBoothButton.action(
    onPressed: context.knobs.boolean(label: "Disabled") ? null: () {},
    child: AutoSizeTextAndIcon(text: 'Print', leftIcon: LucideIcons.printer),
  );
}

@UseCase(name: 'Navigation button', type: PhotoBoothButton)
Widget navigationButton(BuildContext context) {
  return PhotoBoothButton.navigation(
    onPressed: context.knobs.boolean(label: "Disabled") ? null: () {},
    child: AutoSizeTextAndIcon(text: 'Back', leftIcon: LucideIcons.stepBack),
  );
}
