import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lemberfpsmonitor/lemberfpsmonitor.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

class FramerateMonitor extends StatefulWidget {

  final Widget child;

  const FramerateMonitor({super.key, required this.child});

  @override
  State<FramerateMonitor> createState() => _FramerateMonitorState();

}

class _FramerateMonitorState extends State<FramerateMonitor> {

  // Without keying the child, all subtree state get's lost on toggling this,
  // causing duplicate Settings screen on top of each other...
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!getIt<SettingsManager>().settings.debug.showFpsCounter) return KeyedSubtree(key: _childKey, child: widget.child);

      return FPSMonitor(
        showFPSChart: true,
        align: Alignment.topRight,
        onFPSChanged: (fps) {},
        child: KeyedSubtree(key: _childKey, child: widget.child),
      );
    });
  }

}
