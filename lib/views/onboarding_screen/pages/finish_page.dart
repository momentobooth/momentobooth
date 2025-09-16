import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

class FinishPage extends StatefulWidget {

  const FinishPage({super.key});

  @override
  State<FinishPage> createState() => _FinishPageState();

}

class _FinishPageState extends State<FinishPage> with SingleTickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward()
    ..addStatusListener(onAnimationStatusChanged);

  @override
  Widget build(BuildContext context) {
    return WizardPage(
      showBackAction: false,
      showNextAction: false,
      child: Center(
        child: Lottie.asset('assets/animations/Success.json', controller: _controller, frameRate: FrameRate.max),
      ),
    );
  }

  void onAnimationStatusChanged(AnimationStatus status) {
    if (status.isCompleted) context.replace(StartScreen.defaultRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}
