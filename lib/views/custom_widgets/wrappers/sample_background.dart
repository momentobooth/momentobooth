import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/stateless_widget_base.dart';

class SampleBackground extends StatelessWidgetBase {

  static const String _assetPath = "assets/bitmap/sample-background.jpg";

  const SampleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Image.asset(_assetPath, fit: BoxFit.cover),
        ),
        Image.asset(_assetPath, fit: BoxFit.contain),
        
        
      ],
    );
  }

}
