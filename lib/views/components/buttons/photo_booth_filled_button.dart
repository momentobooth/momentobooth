import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';

class PhotoBoothFilledButton extends StatelessWidget {

  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;

  const PhotoBoothFilledButton({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: context.theme.dialogTheme.buttonStyle,
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(icon, size: 24.0),
            ),
          Text(title),
        ],
      ),
    );
  }

}
