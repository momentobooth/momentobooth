import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

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

    GoRouter.of(context).routerDelegate.addListener(_resetTimer);
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
    if (GoRouter.of(context).currentLocation == StartScreen.defaultRoute) return;
    logDebug("Returning to homescreen because Home screen timeout was reached.");
    GoRouter.of(context).go(StartScreen.defaultRoute);
  }

  @override
  void dispose() {
    _returnHomeTimer?.cancel();
    GoRouter.of(context).routerDelegate.removeListener(_resetTimer);
    _resetTimerReactionDisposer();
    super.dispose();
  }

}
