import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  String getFlagAsset(String countryCode) {
    return 'assets/svg/flags/$countryCode.svg';
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    final languages = getIt<ProjectManager>().settings.availableLanguages;

    final TextStyle textStyle = FluentTheme.of(context).typography.bodyLarge!.copyWith(
      fontSize: 30,
    );

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(language.nameNative, style: textStyle),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: SvgPicture.asset(
                          getFlagAsset(language.countryCode),
                          width: textStyle.fontSize,
                        ),
                      ),
                    ]
                  )
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [],
      dialogType: ModalDialogType.input,
    );
  }

}
