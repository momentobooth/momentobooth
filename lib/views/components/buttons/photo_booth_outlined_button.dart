import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/components/buttons/stateless_photo_booth_button.dart';

class PhotoBoothOutlinedButton extends StatelessPhotoBoothButton {

  const PhotoBoothOutlinedButton({
    super.key,
    required super.title,
    super.icon,
    super.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton(
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
      ),
    );
  }

}
