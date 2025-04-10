import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/dialogs/photo_booth_dialog.dart';
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

    return Center(
      child: PhotoBoothDialog(
        width: width,
        height: height,
        title: title,
        body: body,
        indicator: dialogType?.icon,
        actions: actions ??
            [
              PhotoBoothFilledButton(
                title: localizations.genericContinueButton,
                icon: LucideIcons.check,
                onPressed: onDismiss,
              ),
            ],
      ),
    );
  }

}

enum ModalDialogType {

  info,
  warning,
  error,
  success,
  input;

  IconData get _iconData {
    return switch (this) {
      ModalDialogType.info => LucideIcons.info,
      ModalDialogType.warning => LucideIcons.circleAlert,
      ModalDialogType.error => LucideIcons.circleAlert,
      ModalDialogType.success => LucideIcons.circleCheck,
      ModalDialogType.input => LucideIcons.penLine,
    };
  }

  Color get _iconColor {
    return switch (this) {
      ModalDialogType.info || ModalDialogType.input => getIt<ProjectManager>().settings.primaryColor,
      ModalDialogType.warning => const Color(0xffffb900),
      ModalDialogType.error => const Color(0xffd83b01),
      ModalDialogType.success => const Color(0xff107c10),
    };
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
