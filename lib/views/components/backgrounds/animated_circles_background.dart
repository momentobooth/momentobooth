import 'dart:async';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';

class AnimatedCirclesBackground extends StatefulWidget {

  const AnimatedCirclesBackground({super.key});

  @override
  State<AnimatedCirclesBackground> createState() => _AnimatedCirclesBackgroundState();

}

class _AnimatedCirclesBackgroundState extends State<AnimatedCirclesBackground> {

  static const int _gradientCount = 3;

  late final Timer _timer;
  final Random _random = Random();
  late List<Gradient> _gradients;

  Color _getRandomLightBlueTint() {
    final possibleColors = [Colors.blue.light, Colors.blue.lightest];
    final chosenColor = possibleColors[_random.nextInt(possibleColors.length)];
    return chosenColor.withValues(alpha: _random.nextDouble());
  }

  @override
  void initState() {
    _updateGradients();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateGradients(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _updateGradients());

    super.initState();
  }

   void _updateGradients() {
    if (!mounted) return;
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
          colors: [_getRandomLightBlueTint(), const Color.fromARGB(0, 255, 255, 255)],
        ),
        growable: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _gradients
          .map(
            (g) => AnimatedContainer(
              duration: const Duration(seconds: 10),
              decoration: BoxDecoration(gradient: g),
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

}
