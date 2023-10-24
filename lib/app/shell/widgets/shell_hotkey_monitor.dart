import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/managers/_all.dart';

class ShellHotkeyMonitor extends StatelessWidget with UiLoggy {

  final GoRouter router;
  final Widget child;

  const ShellHotkeyMonitor({super.key, required this.router, required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyR, control: control, meta: meta): LiveViewManager.instance.restoreLiveView,
        SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): () {
          if (router.currentLocation == "/settings") {
            // Make sure any overlays are also closed (e.g. dropdowns)
            while (router.currentLocation == "/settings") {
              router.pop();
            }
          } else {
            router.push("/settings");
          }
        },
        SingleActivator(LogicalKeyboardKey.keyF, control: control, meta: meta): WindowManager.instance.toggleFullscreen,
        const SingleActivator(LogicalKeyboardKey.enter, alt: true): WindowManager.instance.toggleFullscreen,
      },
      child: child,
    );
  }

}
