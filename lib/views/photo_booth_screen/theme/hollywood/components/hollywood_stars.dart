import 'package:flutter/material.dart';
import 'package:twinkling_stars/twinkling_stars.dart';

/// Stars background for the Hollywood theme.
///
/// Adapted from [TwinklingStarsBackground].
class HollywoodStars extends StatefulWidget {

  final int starCount;
  final bool includeBigStars;
  final List<Color> starColors;
  final List<StarShape> starShapes;
  final double sizeMultiplier;

  const HollywoodStars({
    super.key,
    this.starCount = 100,
    this.includeBigStars = true,
    this.starColors = const [Colors.white],
    this.starShapes = const [StarShape.fivePoint],
    this.sizeMultiplier = 1,
  });

  @override
  State<HollywoodStars> createState() => _HollywoodStarsState();

}

class _HollywoodStarsState extends State<HollywoodStars> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _stars = List.generate(widget.starCount, (index) {
      final isBig = widget.includeBigStars && (index < widget.starCount * 0.1);
      return Star.random(
        isBigStar: isBig,
        starColors: widget.starColors,
        starShapes: widget.starShapes,
        sizeMultiplier: widget.sizeMultiplier,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            size: constraints.biggest,
            painter: TwinklingStarPainter(_stars, _controller.value),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}
