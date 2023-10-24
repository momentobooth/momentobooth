import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lemberfpsmonitor/lemberfpsmonitor.dart';
import 'package:momento_booth/managers/settings_manager.dart';

class FpsMonitor extends StatelessWidget {

  final Widget child;

  const FpsMonitor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!SettingsManager.instance.settings.debug.showFpsCounter) return child;

      return FPSMonitor(
        showFPSChart: true,
        align: Alignment.topRight,
        onFPSChanged: (fps) {},
        child: child,
      );
    });
  }

}
