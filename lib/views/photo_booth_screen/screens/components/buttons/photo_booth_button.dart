import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

class PhotoBoothButton extends StatelessWidget {

  final ButtonType type;
  final VoidCallback? onPressed;
  final String? title;
  final Widget? child;

  const PhotoBoothButton._({super.key, this.type = ButtonType.action, this.onPressed, this.title, this.child})
    : assert(
        (title == null && child != null) || (title != null && child == null),
        "Either title or child should be given, but not both.",
      );

  const PhotoBoothButton.action({Key? key, VoidCallback? onPressed, String? title, Widget? child})
    : this._(key: key, type: ButtonType.action, onPressed: onPressed, title: title, child: child);

  const PhotoBoothButton.navigation({Key? key, VoidCallback? onPressed, String? title, Widget? child})
    : this._(key: key, type: ButtonType.navigation, onPressed: onPressed, title: title, child: child);

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
      child: child != null ? child! : Text(title!),
    );

    if (buttonTheme.frameBuilder == null) {
      return buttonTheme.frameBuilder!(context, button);
    } else {
      return button;
    }
  }

}

enum ButtonType {

  action,
  navigation,

}
