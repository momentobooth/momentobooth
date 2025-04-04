import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/router.dart';
import 'package:momento_booth/utils/logger.dart';

class ActivityMonitor extends StatefulWidget {

  final Widget child;

  const ActivityMonitor({super.key, required this.child});

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();

}

class _ActivityMonitorState extends State<ActivityMonitor> with Logger {

  Timer? _returnHomeTimer;
  late ReactionDisposer _resetTimerReactionDisposer;

  @override
  void initState() {
    super.initState();

    context.router.addListener(_resetTimer);
    _resetTimerReactionDisposer = autorun((_) => _resetTimer());
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        _onActivity(isTap: false);
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onActivity(isTap: true),
        onPointerSignal: (_) => _onActivity(isTap: false), // This handles scrolling.
        child: widget.child,
      ),
    );
  }

  void _onActivity({bool isTap = false}) {
    if (isTap) {
      getIt<StatsManager>().addTap();
      getIt<SfxManager>().playClickSound();
    }
    _resetTimer();
  }

  void _resetTimer() {
    _returnHomeTimer?.cancel();
    int timeoutSeconds = getIt<SettingsManager>().settings.ui.returnToHomeTimeoutSeconds;
    if (timeoutSeconds > 0) {
      _returnHomeTimer = Timer(Duration(seconds: timeoutSeconds), _goHome);
    }
  }

  void _goHome() {
    if (context.router.topRoute.name == StartRoute.name ||
        context.router.topRoute.name == SettingsRoute.name ||
        context.router.topRoute.name == ManualCollageRoute.name) {
      return;
    }
    logDebug("Returning to homescreen because Home screen timeout was reached.");
    context.router.replaceAll([StartRoute()]);
  }

  @override
  void dispose() {
    _returnHomeTimer?.cancel();
    context.router.removeListener(_resetTimer);
    _resetTimerReactionDisposer();
    super.dispose();
  }

}
