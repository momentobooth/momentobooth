import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/models/settings.dart';

class LottieAnimationWrapper extends StatelessWidget {
  final Widget child;
  final List<LottieAnimationSettings> animationSettings;

  const LottieAnimationWrapper({super.key, required this.child, required this.animationSettings});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        for (LottieAnimationSettings animation in animationSettings)
          Align(
            alignment: Alignment(animation.alignmentX, animation.alignmentY),
            child: Transform.translate(
              offset: Offset(
                animation.offsetDx,
                animation.offsetDy,
              ),
              child: Transform.rotate(
                angle: animation.rotation,
                child: Lottie.file(
                  File(animation.file),
                  height: animation.height,
                  width: animation.width,
                  frameRate: FrameRate.max,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
