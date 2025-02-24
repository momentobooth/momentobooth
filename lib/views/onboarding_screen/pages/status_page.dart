import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_list.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';

class StatusPage extends StatelessWidget {

  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SvgPicture.asset(
                  'assets/svg/undraw_server-status_f685.svg',
                  clipBehavior: Clip.none,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "Initializing components",
                      style: FluentTheme.of(context).typography.title,
                    ),
                  ),
                  Expanded(
                    child: SubsystemStatusList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
