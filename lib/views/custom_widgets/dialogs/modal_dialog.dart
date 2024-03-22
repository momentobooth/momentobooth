import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/photo_booth_dialog.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class ModalDialog extends StatelessWidget {

  final double? width;
  final double? height;
  final String title;
  final ModalDialogType? dialogType;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onDismiss;

  const ModalDialog({
    super.key,
    this.width,
    this.height,
    required this.title,
    this.dialogType = ModalDialogType.info,
    required this.body,
    this.actions,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return PhotoBoothDialog(
      width: width,
      height: height,
      title: title,
      body: body,
      indicator: dialogType?.icon,
      actions: actions ??
          [
            PhotoBoothFilledButton(
              title: localizations.genericContinueButton,
              icon: FontAwesomeIcons.check,
              onPressed: onDismiss,
            ),
          ],
    );
  }

}

enum ModalDialogType {

  info,
  warning,
  error,
  success;

  IconData get _iconData {
    switch (this) {
      case ModalDialogType.info:
        return FontAwesomeIcons.circleInfo;
      case ModalDialogType.warning:
        return FontAwesomeIcons.triangleExclamation;
      case ModalDialogType.error:
        return FontAwesomeIcons.xmark;
      case ModalDialogType.success:
        return FontAwesomeIcons.check;
    }
  }

  Color get _iconColor {
    switch (this) {
      case ModalDialogType.info:
        return const Color(0xff0078d4);
      case ModalDialogType.warning:
        return const Color(0xffffb900);
      case ModalDialogType.error:
        return const Color(0xffd83b01);
      case ModalDialogType.success:
        return const Color(0xff107c10);
    }
  }

  Widget get icon {
    return Icon(_iconData, color: _iconColor);
  }

}

@widgetbook.UseCase(
  name: 'Modal Dialog',
  type: ModalDialog,
)
Widget loadingDialog(BuildContext context) {
  return ModalDialog(
    title: context.knobs.string(label: 'Title', initialValue: 'Please read this'),
    dialogType: context.knobs.list(label: 'Dialog Type', initialOption: ModalDialogType.info, options: ModalDialogType.values),
    body: Text(context.knobs.string(label: 'Body Text', initialValue: 'Something has happened and we just need to acknowledge it.')),
    onDismiss: () {},
  );
}
