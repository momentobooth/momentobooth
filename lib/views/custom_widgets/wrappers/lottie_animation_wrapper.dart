import 'dart:io';

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
      fit: StackFit.passthrough,
      children: [
        child,
        for (LottieAnimationSettings animation in animationSettings)
          LayoutBuilder(
            builder: (context, snapshot) {
              return Transform.translate(
                offset: Offset(
                  0.5 * animation.alignmentX * snapshot.maxWidth + animation.offsetDx,
                  0.5 * animation.alignmentY * snapshot.maxHeight + animation.offsetDy,
                ),
                child: Transform.rotate(
                  angle: animation.rotation,
                  child: Lottie.file(
                    File(animation.file),
                    height: animation.height,
                    width: animation.width,
                  ),
                ),
              );
            }
          ),
      ],
    );
  }
}
