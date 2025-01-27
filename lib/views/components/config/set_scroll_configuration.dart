import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

class SetScrollConfiguration extends StatelessWidget {

  final Widget child;

  const SetScrollConfiguration({super.key, required this.child});

  bool get _allowScrollGestureWithMouse => getIt<SettingsManager>().settings.ui.allowScrollGestureWithMouse;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!_allowScrollGestureWithMouse) return child;

      ScrollBehavior oldBehavior = ScrollConfiguration.of(context);
      return ScrollConfiguration(
        behavior: oldBehavior.copyWith(
          dragDevices: {
            ...oldBehavior.dragDevices,
            PointerDeviceKind.mouse,
          },
        ),
        child: child,
      );
    });
  }

}
