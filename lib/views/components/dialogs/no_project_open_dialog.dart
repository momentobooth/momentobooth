import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class NoProjectOpenDialog extends StatelessWidget {

  // final VoidCallback onIgnorePressed;
  final VoidCallback onOpened;

  const NoProjectOpenDialog({
    super.key,
    // required this.onIgnorePressed,
    required this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    final recentProjects = getIt<ProjectManager>().listProjects().take(5);

    return ModalDialog(
      title: localizations.projectNotOpened,
      body: Column(
        children: [
          Text(
            localizations.projectNotOpenedInstructions,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            localizations.projectNotOpenedExplanation,
          ),
          SizedBox(height: 20.0,),
          Text(
            "${localizations.projectsRecent}:",
          ),
          SizedBox(height: 8.0,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            for (final project in recentProjects)
              Material(
                color: Color.fromARGB(0, 0, 0, 0),
                child: InkWell(
                  onTap: () {
                    getIt<ProjectManager>().open(project.path);
                    onOpened();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: [
                      Text(project.name, style: FluentTheme.of(context).typography.bodyStrong),
                      Text("${localizations.opened}: ${project.opened}"),
                    ],),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 8.0,),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.projectLoadLastOnStart),
              SizedBox(width: 8.0,),
              ToggleSwitch(
                checked: getIt<SettingsManager>().settings.loadLastProject,
                onChanged: (val) => getIt<SettingsManager>().updateAndSave(getIt<SettingsManager>().settings.copyWith(loadLastProject: val)),
              ),
            ],
          ),
          Text("(${localizations.genericCanBeChangedInSettings})"),
        ],
      ),
      actions: [
        PhotoBoothFilledButton(
          title: localizations.projectOpenButton,
          icon: LucideIcons.folderInput,
          onPressed: () async {
            final opened = await getIt<ProjectManager>().browseOpen();
            if (opened) {
              onOpened();
            }
          },
        ),
      ],
      dialogType: ModalDialogType.warning,
    );
  }

}
