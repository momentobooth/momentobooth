import 'dart:async';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/src/rust/models/version_info.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:momento_booth/views/custom_widgets/onboarding_version_info.dart';

class OnboardingPage extends StatefulWidget {

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();

}

class _OnboardingPageState extends State<OnboardingPage> {

  static const int _gradientCount = 3;

  final _random = Random();
  late List<Gradient> _gradients;

  @override
  void initState() {
    _updateGradients();

    Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateGradients(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _updateGradients());

    super.initState();
  }

  void _updateGradients() {
    setState(() {
      _gradients = List.generate(
          _gradientCount,
          (i) => RadialGradient(
                radius: _random.nextDouble() / 3 + 0.30,
                center: Alignment(
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                ),
                focalRadius: 100,
                colors: [
                  _getRandomLightBlueTint(),
                  const Color.fromARGB(0, 255, 255, 255),
                ],
              ),
          growable: false);
    });
  }

  Color _getRandomLightBlueTint() {
    final possibleColors = [Colors.blue.light, Colors.blue.lightest];
    final chosenColor = possibleColors[_random.nextInt(possibleColors.length)];
    return chosenColor.withOpacity(_random.nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    //final FluentThemeData themeData = FluentTheme.of(context);
    ObservableList list = getIt.get<ObservableList<Subsystem>>();
    print(list);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        ..._gradients.map((g) => AnimatedContainer(
              duration: const Duration(seconds: 10),
              decoration: BoxDecoration(
                gradient: g,
              ),
            )),
        Center(
          child: SizedBox(
            width: 800,
            height: 500,
            child: _getCenterWidget(context),
          ),
        ),
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: OnboardingVersionInfo(
        //     appVersionInfo: _appVersionInfo,
        //   ),
        // ),
      ],
    );
  }

  Widget _getCenterWidget(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: const Column(
        children: [
          Expanded(
            child: Center(child: ProgressRing()),
          ),
        ],
      ),
    );
  }

}
