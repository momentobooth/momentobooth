import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PhotoBoothButton extends StatelessWidget {

  final ButtonType type;
  final VoidCallback? onPressed;
  final Widget child;

  const PhotoBoothButton._({super.key, this.type = ButtonType.action, this.onPressed, required this.child});

  const PhotoBoothButton.action({Key? key, VoidCallback? onPressed, required Widget child})
    : this._(key: key, type: ButtonType.action, onPressed: onPressed, child: child);

  const PhotoBoothButton.navigation({Key? key, VoidCallback? onPressed, required Widget child})
    : this._(key: key, type: ButtonType.navigation, onPressed: onPressed, child: child);

  @override
  Widget build(BuildContext context) {
    PhotoBoothTheme theme = FluentTheme.of(context).photoBoothTheme;
    PhotoBoothButtonTheme buttonTheme = switch (type) {
      ButtonType.action => theme.actionButtonTheme,
      ButtonType.navigation => theme.navigationButtonTheme,
    };

    Widget button = Button(
      style: buttonTheme.style,
      onPressed: onPressed,
      child: child,
    );

    return buttonTheme.frameBuilder?.call(context, button) ?? button;
  }

}

enum ButtonType {

  action,
  navigation,

}

@UseCase(name: 'Action button', type: PhotoBoothButton)
Widget actionButton(BuildContext context) {
  return PhotoBoothButton.action(child: AutoSizeTextAndIcon(text: 'Print', leftIcon: LucideIcons.printer));
}

@UseCase(name: 'Navigation button', type: PhotoBoothButton)
Widget navigationButton(BuildContext context) {
  return PhotoBoothButton.navigation(child: AutoSizeTextAndIcon(text: 'Back', leftIcon: LucideIcons.stepBack));
}
