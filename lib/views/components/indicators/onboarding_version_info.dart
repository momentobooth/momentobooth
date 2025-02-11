import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/models/app_version_info.dart';

class OnboardingVersionInfo extends StatelessWidget {

  final AppVersionInfo appVersionInfo;

  const OnboardingVersionInfo({super.key, required this.appVersionInfo});

  @override
  Widget build(BuildContext context) {
    return Text(
      'MomentoBooth ${appVersionInfo.appVersion}\n'
        'Built with Flutter ${appVersionInfo.flutterVersion}, Rust ${appVersionInfo.rustVersion} (with target ${appVersionInfo.rustTarget})',
      textAlign: TextAlign.center,
    );
  }

}
