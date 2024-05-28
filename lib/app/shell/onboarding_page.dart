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

  final _random = Random();
  final List<Gradient> _gradients = [const RadialGradient(colors: []), const RadialGradient(colors: []), const RadialGradient(colors: [])];

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
      for (var i = 0; i < _gradients.length; i++) {
        _gradients[i] = RadialGradient(
          radius: _random.nextDouble() / 3 + 0.30,
          center: Alignment(
            _random.nextDouble() * (_random.nextBool() ? -1 : 1),
            _random.nextDouble() * (_random.nextBool() ? -1 : 1),
          ),
          focalRadius: 100,
          colors: [
            [Colors.blue.light.withOpacity(_random.nextDouble()), Colors.blue.lightest.withOpacity(_random.nextDouble())][_random.nextInt(2)],
            const Color.fromARGB(0, 255, 255, 255),
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final FluentThemeData themeData = FluentTheme.of(context);

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
