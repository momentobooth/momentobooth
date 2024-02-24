import 'package:flutter/widgets.dart';
import 'package:momento_booth/models/settings.dart';

class RotateFlipCropContainer extends StatelessWidget {

  final Widget child;
  final Rotate rotate;
  final Flip flip;
  final double aspectRatio;

  const RotateFlipCropContainer({super.key, 
    required this.child,
    required this.rotate,
    required this.flip,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: aspectRatio,
      height: 1,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: Transform.flip(
          flipX: flip == Flip.horizontally,
          flipY: flip == Flip.vertically,
          child: RotatedBox(
            quarterTurns: rotate.quarterTurns,
            child: child,
          ),
        ),
      ),
    );
  }

}
