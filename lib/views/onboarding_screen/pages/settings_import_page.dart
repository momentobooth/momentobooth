import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';
import 'package:momento_booth/views/settings_screen/components/import_field.dart';

class SettingsImportPage extends StatelessWidget {

  const SettingsImportPage({super.key});

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
                "Import settings preset",
                style: FluentTheme.of(context).typography.title,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "Here you can import a settings file to preset e.g. your template and print settings to the right values for your event. "
              "If this is not relevant for you, feel free to skip this. You will see a preview of the settings that will be changed.",
              style: FluentTheme.of(context).typography.body,
            ),
            SizedBox(height: 16.0),
            MyDropRegion(),
          ],
        ),
      ),
    );
  }

}
