import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';

class ProjectsPage extends StatelessWidget {

  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Let's open your first project!",
                style: FluentTheme.of(context).typography.title,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "Open a directory (create one if you like) to use for a project. This directory will be used to store your pictures and collages. It is also where MomentoBooth will look for templates.",
              style: FluentTheme.of(context).typography.body,
            ),
            SizedBox(height: 16.0),
            FilledButton(
              onPressed: () => getIt<ProjectManager>().browseOpen(),
              child: Text("Open folder"),
            ),
          ],
        ),
      ),
    );
  }

}
