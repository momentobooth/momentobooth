import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';

class PhotoBoothHotkeyMonitor extends StatelessWidget with Logger {

  final GoRouter router;
  final Widget child;

  const PhotoBoothHotkeyMonitor({super.key, required this.router, required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): () => router.go(StartScreen.defaultRoute),
        SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): _toggleManualCollageScreen,
      },
      child: child,
    );
  }

  void _toggleManualCollageScreen() {
    if (router.currentLocation == ManualCollageScreen.defaultRoute) {
      router.go(StartScreen.defaultRoute);
    } else {
      router.go(ManualCollageScreen.defaultRoute);
    }
  }

}
