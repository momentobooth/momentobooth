import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class BlockingDialog extends StatelessWidget {

  final String title;
  final Widget child;

  const BlockingDialog({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      width: 800,
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.75),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 40,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(title),
          Expanded(child: child),
        ],
      ),
    );
  }

}
