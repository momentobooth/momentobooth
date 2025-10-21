import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class LanguageChoiceDialog extends StatelessWidget {

  final Function(Language) onChosen;

  const LanguageChoiceDialog({
    super.key,
    required this.onChosen,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    final languages = getIt<ProjectManager>().settings.availableLanguages;

    return ModalDialog(
      title: "Choose your language",
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          for (final language in languages)
            Material(
              color: Color.fromARGB(0, 0, 0, 0),
              child: InkWell(
                onTap: () {
                  onChosen(language);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(text: language.nameNative, style: FluentTheme.of(context).typography.bodyLarge),
                        TextSpan(text: language.flag, style: GoogleFonts.notoColorEmoji(textStyle: FluentTheme.of(context).typography.bodyLarge)),
                        TextSpan(text: "😊", style: FluentTheme.of(context).typography.bodyLarge),
                      ]
                    )
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      actions: [],
      dialogType: ModalDialogType.input,
    );
  }

}
