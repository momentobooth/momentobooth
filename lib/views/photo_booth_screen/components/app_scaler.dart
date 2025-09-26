import 'dart:math';

import 'package:flutter/widgets.dart';

class AppScaler extends StatelessWidget {
  const AppScaler({
    super.key,
    required this.child,
  });

  /// The widget that should be scaled.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The target resolution for the scale of the UI, based on a full HD screen.
    const double targetWidth = 1920;
    const double targetHeight = 1080;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the scaling factors based on the target dimensions.
        final double widthScale = constraints.maxWidth / targetWidth;
        final double heightScale = constraints.maxHeight / targetHeight;

        // We want to scale to the most constraining dimension, the scaling factor is therfore the minimum of the two.
        // This ensures the content always fits within the window without letterboxing.
        final double scaleFactor = min(widthScale, heightScale);

        // Calculate the new size of the scaled content.
        final double scaledWidth = constraints.maxWidth / scaleFactor;
        final double scaledHeight = constraints.maxHeight / scaleFactor;

        return FittedBox(
          child: SizedBox(
            width: scaledWidth,
            height: scaledHeight,
            child: child,
          ),
        );
      },
    );
  }
}
