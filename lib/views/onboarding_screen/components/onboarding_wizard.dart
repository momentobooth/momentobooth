import 'package:fluent_ui/fluent_ui.dart';

class OnboardingWizard extends StatelessWidget {

  final Widget child;

  const OnboardingWizard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 500,
      child: Acrylic(
        elevation: 16.0,
        luminosityAlpha: 0.9,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        child: child,
      ),
    );
  }

}
