import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/app_init_manager.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';

class ErrorPage extends StatelessWidget {

  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      showNextAction: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text("Error!", style: FluentTheme.of(context).typography.title),
            Text("A fatal error occured while initializing the application. MomentoBooth cannot continue.\n\nPlease review the exception below, try to resolve the issue then restart the application to try again."),
            Expanded(child: ListView(
              children: [
                Text("Exception", style: FluentTheme.of(context).typography.subtitle),
                const SizedBox(height: 8),
                Text(getIt<AppInitManager>().exception?.toString() ?? 'Unknown error'),
                const SizedBox(height: 16),
                Text("Stacktrace", style: FluentTheme.of(context).typography.subtitle),
                const SizedBox(height: 8),
                Text(getIt<AppInitManager>().stackTrace?.toString() ?? 'Unknown stacktrace'),
              ],
            )),
          ],
        ),
      ),
    );
  }

}
