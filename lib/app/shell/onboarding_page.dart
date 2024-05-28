import 'dart:async';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

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
      _gradients = List.generate(_gradientCount, (i) => RadialGradient(
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
        ), growable: false);
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
        LayoutGrid(
          columnGap: 12,
          rowGap: 12,
          areas: '''
                  lt t rt
                  l  B r
                  lb b rb
                ''',
          // A number of extension methods are provided for concise track sizing
          columnSizes: [
            1.4.fr,
            5.0.fr,
            1.4.fr,
          ],
          rowSizes: [
            0.8.fr,
            5.0.fr,
            0.8.fr,
          ],
          children: [
            gridArea('B').containing(Builder(builder: _getCenterWidget)),
          ],
        ),
      ],
    );
  }

  Widget _getCenterWidget(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(34, 0, 34, 34),
              child: const Center(child: ProgressRing()),
            ),
          ),
        ],
      ),
    );
  }

}
