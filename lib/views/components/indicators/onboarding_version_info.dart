import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/models/app_version_info.dart';

class OnboardingVersionInfo extends StatelessWidget {

  final AppVersionInfo appVersionInfo;

  const OnboardingVersionInfo({super.key, required this.appVersionInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'MomentoBooth ${appVersionInfo.appVersion}\n'
          'Built with Flutter ${appVersionInfo.flutterVersion}, Rust ${appVersionInfo.rustVersion}',
        textAlign: TextAlign.center,
      ),
    );
  }

}
