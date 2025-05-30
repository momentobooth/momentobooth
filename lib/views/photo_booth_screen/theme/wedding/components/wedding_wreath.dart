import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class WeddingWreath extends StatefulWidget {

  const WeddingWreath({super.key});

  @override
  State<WeddingWreath> createState() => _WeddingWreathState();

}

class _WeddingWreathState extends State<WeddingWreath> with TickerProviderStateMixin {

  static const double _lottieLoopStart = 0.4, _lottieLoopEnd = 0.65;
  static const double _lottieLoopTimeDilation = 5;
  static const Duration _rotationTime = Duration(seconds: 360);

  late final AnimationController _lottieController = AnimationController(vsync: this);
  late final AnimationController _rotationController = AnimationController(vsync: this, duration: _rotationTime)..repeat();

  bool _looping = false;
  Duration? _originalDuration;

  @override
  void initState() {
    super.initState();

    _lottieController.addListener(() {
      if (!_looping && _lottieController.value >= _lottieLoopEnd) {
        _looping = true;

        // Dilate time after loop as started.
        if (_originalDuration != null) {
          _lottieController.duration = _originalDuration! * _lottieLoopTimeDilation;
        }

        _lottieController.reverse();
      } else if (_looping) {
        if (_lottieController.status == AnimationStatus.forward && _lottieController.value >= _lottieLoopEnd) {
          _lottieController.reverse();
        } else if (_lottieController.status == AnimationStatus.reverse && _lottieController.value <= _lottieLoopStart) {
          _lottieController.forward();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Transform.scale(
        scale: 1.25,
        child: Lottie.asset(
          'assets/animations/Animation - 1744059648062.json',
          fit: BoxFit.contain,
          frameRate: FrameRate.max,
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController
              ..duration = _originalDuration = composition.duration
              ..forward();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

}

@UseCase(name: "Default", type: WeddingWreath)
Widget weddingWreathUseCase(BuildContext context) {
  return SizedBox.expand(child: const WeddingWreath());
}
