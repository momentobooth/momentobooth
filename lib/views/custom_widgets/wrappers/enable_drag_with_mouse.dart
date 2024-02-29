import 'dart:ui';

import 'package:flutter/widgets.dart';

class EnableDragWithMouse extends StatelessWidget {

  final Widget child;

  const EnableDragWithMouse({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ScrollBehavior oldBehavior = ScrollConfiguration.of(context);

    return ScrollConfiguration(
      behavior: oldBehavior.copyWith(
        dragDevices: {...oldBehavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: child,
    );
  }

}
