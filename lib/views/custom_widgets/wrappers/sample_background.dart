import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/managers/live_view_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/stateless_widget_base.dart';

class CameraBackground extends StatelessWidgetBase {
  final Widget child;

  const CameraBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.green),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Observer(builder: (_) {
            return RawImage(
              image: LiveViewManagerBase.instance.lastFrameImage,
              fit: BoxFit.cover,
            );
          }),
        ),
        Observer(builder: (_) {
          return RawImage(
            image: LiveViewManagerBase.instance.lastFrameImage,
            fit: BoxFit.contain,
          );
        }),
        child,
      ],
    );
  }
}
