import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
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
      title: "No project opened",
      body: Column(
        children: [
          Text(
            "You did not open a project folder yet. Open one to start capturing.",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "MomentoBooth needs to know where to store images and look for collage templates.",
          ),
          SizedBox(height: 20.0,),
          Text(
            "Recent projects:",
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
                      Text("Opened: ${project.opened}"),
                    ],),
                  ),
                ),
              )
          ],)
        ],
      ),
      actions: [
        PhotoBoothFilledButton(
          title: "Open a project folder",
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
